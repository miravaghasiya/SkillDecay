import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/question_model.dart';

class QuizService {
  static final Map<String, Set<String>> _sessionGeneratedQuestionsBySkill = {};

  static const List<String> _defaultFreeModels = [
    'openai/gpt-oss-120b:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'qwen/qwen3-32b:free',
    'mistralai/mistral-7b-instruct:free',
  ];

  String get _apiKey {
    return dotenv.env['QUIZ_API_KEY'] ?? dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }

  String get _baseUrl {
    return dotenv.env['QUIZ_API_BASE_URL'] ??
        dotenv.env['OPENROUTER_BASE_URL'] ??
        '';
  }

  String get _model {
    return dotenv.env['QUIZ_MODEL'] ?? dotenv.env['OPENROUTER_MODEL'] ?? '';
  }

  List<String> get _models {
    final configured = dotenv.env['QUIZ_FREE_MODELS'] ?? '';
    if (configured.trim().isNotEmpty) {
      return configured
          .split(',')
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty)
          .toList();
    }
    if (_model.trim().isNotEmpty) {
      return [_model.trim()];
    }
    return List<String>.from(_defaultFreeModels);
  }

  int get _questionCount => _readEnvInt('QUIZ_QUESTION_COUNT', fallback: 5);
  int get _generationBatchSize =>
      _readEnvInt('QUIZ_GENERATION_BATCH_SIZE', fallback: 8);
  int get _maxAttempts => _readEnvInt('QUIZ_MAX_ATTEMPTS', fallback: 3);
  int get _timeoutSeconds => _readEnvInt('QUIZ_TIMEOUT_SECONDS', fallback: 40);
  int get _historyLimit => _readEnvInt('QUIZ_HISTORY_LIMIT', fallback: 80);

  int _readEnvInt(String key, {required int fallback}) {
    final raw = dotenv.env[key];
    if (raw == null || raw.trim().isEmpty) {
      return fallback;
    }
    return int.tryParse(raw.trim()) ?? fallback;
  }

  void _validateConfiguration() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Quiz API key is missing. Configure QUIZ_API_KEY or OPENROUTER_API_KEY in .env.',
      );
    }
    if (_baseUrl.isEmpty) {
      throw Exception(
        'Quiz API base URL is missing. Configure QUIZ_API_BASE_URL or OPENROUTER_BASE_URL in .env.',
      );
    }
    if (_models.isEmpty) {
      throw Exception(
        'Quiz model is missing. Configure QUIZ_MODEL, OPENROUTER_MODEL, or QUIZ_FREE_MODELS in .env.',
      );
    }
    for (final model in _models) {
      if (!model.toLowerCase().contains(':free')) {
        throw Exception(
          'Only free models are allowed. Invalid model: $model. Use :free models only.',
        );
      }
    }
  }

  Future<List<QuestionModel>> generateQuizBatch({
    required String skillId,
    required String skillTitle,
    required String category,
    required String userLevel, // Beginner, Intermediate, Advanced
    required double mastery, // 0-100
    List<String> previousQuestions = const [],
  }) async {
    return generateQuiz(
      skillId: skillId,
      skillName: skillTitle,
      category: category,
      userLevel: userLevel,
      mastery: mastery,
      previousQuestions: previousQuestions,
    );
  }

  Future<List<QuestionModel>> generateQuiz({
    required String skillId,
    required String skillName,
    required String category,
    required String userLevel,
    required double mastery,
    List<String> previousQuestions = const [],
    String? userId,
  }) async {
    _validateConfiguration();

    final effectiveUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    final recentQuestionHistory = await _fetchRecentQuizHistory(
      userId: effectiveUserId,
      skillId: skillId,
    );
    final sessionHistory =
        _sessionGeneratedQuestionsBySkill[skillId] ?? <String>{};
    final combinedPrevious = {
      ...previousQuestions.map(_normalizeQuestionKey),
      ...recentQuestionHistory.map(_normalizeQuestionKey),
      ...sessionHistory,
    };

    final notesContext = await _fetchSkillNotesContext(
      userId: effectiveUserId,
      skillId: skillId,
    );

    try {
      final questions = <QuestionModel>[];
      final seenQuestions = <String>{};

      for (
        var attempt = 0;
        attempt < _maxAttempts && questions.length < _questionCount;
        attempt++
      ) {
        final avoidQuestionTexts = {
          ...combinedPrevious,
          ...seenQuestions,
        }.toList();

        final prompt = _buildQuizPrompt(
          skillName: skillName,
          category: category,
          userLevel: userLevel,
          mastery: mastery,
          previousQuestions: avoidQuestionTexts,
          notesContext: notesContext,
          questionCount: _generationBatchSize,
        );

        final response = await _callAi(prompt);
        final parsed = _parseQuestions(response);
        final filtered = _filterUniqueQuestions(
          parsed,
          blockedQuestionKeys: combinedPrevious,
          seenQuestionKeys: seenQuestions,
        );

        for (final question in filtered) {
          if (questions.length >= _questionCount) {
            break;
          }
          questions.add(question);
          seenQuestions.add(_normalizeQuestionKey(question.question));
        }
      }

      if (questions.isEmpty) {
        throw Exception('No quiz questions generated from AI response.');
      }

      final result = questions.take(_questionCount).toList();
      _sessionGeneratedQuestionsBySkill.putIfAbsent(skillId, () => <String>{});
      _sessionGeneratedQuestionsBySkill[skillId]!.addAll(
        result.map((q) => _normalizeQuestionKey(q.question)),
      );

      return result;
    } catch (e) {
      debugPrint('Quiz generation failed: $e');
      final fallback = _buildLocalFallbackQuestions(
        skillName: skillName,
        userLevel: userLevel,
        blockedQuestionKeys: combinedPrevious,
      );
      if (fallback.isNotEmpty) {
        _sessionGeneratedQuestionsBySkill.putIfAbsent(
          skillId,
          () => <String>{},
        );
        _sessionGeneratedQuestionsBySkill[skillId]!.addAll(
          fallback.map((q) => _normalizeQuestionKey(q.question)),
        );
        return fallback;
      }
      throw Exception('Could not generate quiz right now. Please try again.');
    }
  }

  String _buildQuizPrompt({
    required String skillName,
    required String category,
    required String userLevel,
    required double mastery,
    required List<String> previousQuestions,
    required String notesContext,
    int questionCount = 5,
  }) {
    final previous = previousQuestions.isEmpty
        ? 'None'
        : previousQuestions.map((q) => '- $q').join('\n');

    return '''
  Generate $questionCount multiple-choice questions about "$skillName".

Learner profile:
- Category: $category
- Level: $userLevel
- Mastery score: ${mastery.toStringAsFixed(1)} / 100

Skill notes/context from the user (if available):
$notesContext

Avoid repeating these previous questions:
$previous

For each question include:
- question
- options (exactly 4 options)
- correctAnswerIndex (0 to 3)
- explanation (short)

Strict uniqueness rules:
- Do not repeat a question in this output.
- Do not use semantically duplicate question wording.
- Do not repeat any question listed under "Avoid repeating".

Return JSON only in this shape:
{
  "questions": [
    {
      "question": "...",
      "options": ["...", "...", "...", "..."],
      "correctAnswerIndex": 0,
      "explanation": "..."
    }
  ]
}
''';
  }

  Future<String> _callAi(String prompt) async {
    final errors = <String>[];

    for (final model in _models) {
      try {
        return await _callAiWithModel(prompt: prompt, model: model);
      } catch (e) {
        errors.add('$model -> $e');
      }
    }

    throw Exception('All free models failed: ${errors.join(' | ')}');
  }

  Future<String> _callAiWithModel({
    required String prompt,
    required String model,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            if (_baseUrl.contains('openrouter.ai'))
              'HTTP-Referer':
                  dotenv.env['QUIZ_HTTP_REFERER'] ?? 'http://localhost',
            if (_baseUrl.contains('openrouter.ai'))
              'X-Title':
                  dotenv.env['QUIZ_APP_TITLE'] ?? 'Micro Skill Decay Detector',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.4,
            'messages': [
              {
                'role': 'system',
                'content': 'You are a quiz generator. Return valid JSON only.',
              },
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(Duration(seconds: _timeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = _extractApiErrorDetail(response.body);
      throw Exception(
        'AI API status ${response.statusCode}${detail.isEmpty ? '' : ': $detail'}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception('AI API returned no choices.');
    }

    final content = choices.first['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('AI API returned empty content.');
    }

    return content;
  }

  String _extractApiErrorDetail(String responseBody) {
    try {
      final parsed = jsonDecode(responseBody);
      if (parsed is Map<String, dynamic>) {
        final error = parsed['error'];
        if (error is Map<String, dynamic>) {
          final message = '${error['message'] ?? ''}'.trim();
          if (message.isNotEmpty) {
            return message;
          }
        }
        final message = '${parsed['message'] ?? ''}'.trim();
        if (message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Best-effort only.
    }
    final compact = responseBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '';
    }
    return compact.length > 180 ? '${compact.substring(0, 180)}...' : compact;
  }

  List<QuestionModel> _parseQuestions(String content) {
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json|```'), '').trim();
    }

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    final jsonText = match?.group(0) ?? cleaned;

    final parsed = jsonDecode(jsonText);
    final dynamic rawQuestions = parsed is Map<String, dynamic>
        ? parsed['questions'] ?? parsed['data']
        : parsed;

    if (rawQuestions is! List) {
      throw Exception('Invalid question payload.');
    }

    return rawQuestions
        .whereType<Map<String, dynamic>>()
        .map(QuestionModel.fromJson)
        .where((q) => q.question.isNotEmpty)
        .toList();
  }

  List<QuestionModel> _filterUniqueQuestions(
    List<QuestionModel> questions, {
    required Set<String> blockedQuestionKeys,
    required Set<String> seenQuestionKeys,
  }) {
    final unique = <QuestionModel>[];

    for (final question in questions) {
      final key = _normalizeQuestionKey(question.question);
      if (key.isEmpty) {
        continue;
      }
      if (blockedQuestionKeys.contains(key) || seenQuestionKeys.contains(key)) {
        continue;
      }
      unique.add(question);
      seenQuestionKeys.add(key);
    }

    return unique;
  }

  List<QuestionModel> _buildLocalFallbackQuestions({
    required String skillName,
    required String userLevel,
    required Set<String> blockedQuestionKeys,
  }) {
    final templates = <Map<String, dynamic>>[
      {
        'question':
            'What is the most important first step when learning $skillName?',
        'options': [
          'Understand core concepts and terminology',
          'Memorize advanced tricks immediately',
          'Skip fundamentals and build directly',
          'Avoid practicing until everything is clear',
        ],
        'correctAnswerIndex': 0,
        'explanation': 'Strong fundamentals accelerate long-term progress.',
      },
      {
        'question':
            'Which practice method most improves retention for $skillName?',
        'options': [
          'Spaced repetition with active recall',
          'Reading notes once per month',
          'Watching tutorials without practice',
          'Only practicing before exams',
        ],
        'correctAnswerIndex': 0,
        'explanation': 'Frequent retrieval over time is best for memory.',
      },
      {
        'question': 'How can you verify progress in $skillName effectively?',
        'options': [
          'Track measurable outcomes after each session',
          'Rely only on motivation levels',
          'Ignore mistakes and move on',
          'Practice randomly without review',
        ],
        'correctAnswerIndex': 0,
        'explanation': 'Metrics reveal improvement and weak areas.',
      },
      {
        'question': 'What is a common mistake when practicing $skillName?',
        'options': [
          'Repeating only easy tasks',
          'Reviewing feedback regularly',
          'Scheduling consistent sessions',
          'Breaking tasks into smaller goals',
        ],
        'correctAnswerIndex': 0,
        'explanation': 'Improvement requires challenging weak points.',
      },
      {
        'question':
            'Which plan best supports intermediate growth in $skillName?',
        'options': [
          'Mix fundamentals, challenges, and reflection',
          'Practice only favorite topics',
          'Avoid timed exercises completely',
          'Wait for perfect conditions before practice',
        ],
        'correctAnswerIndex': 0,
        'explanation': 'Balanced practice improves both depth and consistency.',
      },
      {
        'question':
            'What should you do after a mistake in $skillName practice?',
        'options': [
          'Analyze cause and retry with adjustment',
          'Skip that topic forever',
          'Assume you are not capable',
          'Start a different skill immediately',
        ],
        'correctAnswerIndex': 0,
        'explanation': 'Mistake analysis turns errors into learning gains.',
      },
    ];

    final seen = <String>{...blockedQuestionKeys};
    final fallback = <QuestionModel>[];

    for (final template in templates) {
      final questionText = '${template['question'] ?? ''}'.trim();
      final key = _normalizeQuestionKey(questionText);
      if (questionText.isEmpty || seen.contains(key)) {
        continue;
      }

      fallback.add(
        QuestionModel.fromJson({
          'id': 'fallback-${skillName.hashCode}-${fallback.length}',
          'question': questionText,
          'options': template['options'],
          'correctAnswerIndex': template['correctAnswerIndex'],
          'explanation': template['explanation'],
          'difficulty': userLevel.toLowerCase(),
        }),
      );
      seen.add(key);

      if (fallback.length >= _questionCount) {
        break;
      }
    }

    return fallback;
  }

  String _normalizeQuestionKey(String question) {
    return question.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<List<String>> _fetchRecentQuizHistory({
    required String? userId,
    required String skillId,
  }) async {
    if (userId == null || skillId.isEmpty) {
      return const [];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('quiz_history')
          .doc(skillId)
          .get();

      if (!doc.exists) {
        return const [];
      }

      final data = doc.data() ?? <String, dynamic>{};
      final values = data['recentQuestions'];
      if (values is! List) {
        return const [];
      }

      return values.map((e) => '$e').toList();
    } catch (e) {
      debugPrint('Failed to load recent quiz history: $e');
      return const [];
    }
  }

  Future<void> saveQuizHistory({
    required String userId,
    required String skillId,
    required List<QuestionModel> questions,
  }) async {
    if (userId.isEmpty || skillId.isEmpty || questions.isEmpty) {
      return;
    }

    final newQuestionKeys = questions
        .map((q) => _normalizeQuestionKey(q.question))
        .where((q) => q.isNotEmpty)
        .toList();

    if (newQuestionKeys.isEmpty) {
      return;
    }

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('quiz_history')
        .doc(skillId);

    try {
      final existing = await historyRef.get();
      final existingList = existing.exists
          ? List<String>.from(
              (existing.data()?['recentQuestions'] ?? const []) as List,
            )
          : <String>[];

      final merged = <String>{...newQuestionKeys, ...existingList}.toList();

      // Keep only most recent set to bound document size.
      final bounded = merged.take(_historyLimit).toList();

      await historyRef.set({
        'recentQuestions': bounded,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save quiz history: $e');
    }
  }

  Future<String> _fetchSkillNotesContext({
    required String? userId,
    required String skillId,
  }) async {
    if (userId == null || skillId.isEmpty) {
      return 'No additional notes provided.';
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('skills')
          .doc(skillId)
          .get();

      if (!snapshot.exists) {
        return 'No additional notes provided.';
      }

      final data = snapshot.data() ?? {};
      final notes = '${data['notes'] ?? ''}'.trim();
      final weakTopics = (data['weakTopics'] is List)
          ? List<String>.from((data['weakTopics'] as List).map((e) => '$e'))
          : <String>[];

      if (notes.isEmpty && weakTopics.isEmpty) {
        return 'No additional notes provided.';
      }

      final weakTopicsText = weakTopics.isEmpty
          ? ''
          : '\nWeak topics: ${weakTopics.join(', ')}';
      return 'Notes: $notes$weakTopicsText';
    } catch (_) {
      return 'No additional notes provided.';
    }
  }

  void clearCache(String skillId) {
    // Caching is intentionally disabled for generation to avoid repeated quizzes.
    _sessionGeneratedQuestionsBySkill.remove(skillId);
  }

  // Kept for backward compatibility while backend dependency is removed.
  Future<void> saveSession() async {}
}
