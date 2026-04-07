import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CoachMessage {
  final String role; // 'user' | 'ai'
  final String text;
  final DateTime timestamp;

  CoachMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

class CoachService {
  static const List<String> _defaultFreeModels = [
    'openai/gpt-oss-120b:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'qwen/qwen3-32b:free',
    'mistralai/mistral-7b-instruct:free',
  ];

  String get _apiKey {
    return dotenv.env['COACH_API_KEY'] ??
        dotenv.env['OPENROUTER_API_KEY'] ??
        '';
  }

  String get _baseUrl {
    final configured =
        dotenv.env['COACH_API_BASE_URL'] ??
        dotenv.env['OPENROUTER_BASE_URL'] ??
        '';
    if (configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return 'https://openrouter.ai/api/v1';
  }

  String get _model {
    return dotenv.env['COACH_MODEL'] ?? dotenv.env['OPENROUTER_MODEL'] ?? '';
  }

  List<String> get _models {
    final configured = dotenv.env['COACH_FREE_MODELS'] ?? '';
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

  int get _timeoutSeconds {
    final raw = dotenv.env['COACH_TIMEOUT_SECONDS'];
    if (raw == null || raw.trim().isEmpty) {
      return 40;
    }
    return int.tryParse(raw.trim()) ?? 40;
  }

  int get _maxRetries {
    final raw = dotenv.env['COACH_MAX_RETRIES'];
    if (raw == null || raw.trim().isEmpty) {
      return 2;
    }
    return int.tryParse(raw.trim()) ?? 2;
  }

  int get _retrievedSkillLimit {
    final raw = dotenv.env['COACH_RETRIEVED_SKILL_LIMIT'];
    if (raw == null || raw.trim().isEmpty) {
      return 5;
    }
    return int.tryParse(raw.trim()) ?? 5;
  }

  int get _recentHistoryLimit {
    final raw = dotenv.env['COACH_HISTORY_LIMIT'];
    if (raw == null || raw.trim().isEmpty) {
      return 4;
    }
    return int.tryParse(raw.trim()) ?? 4;
  }

  void _validateConfiguration() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Coach API key is missing. Configure COACH_API_KEY or OPENROUTER_API_KEY in .env.',
      );
    }
    for (final model in _models) {
      if (!model.toLowerCase().contains(':free')) {
        throw Exception(
          'Only free models are allowed for coach. Invalid model: $model',
        );
      }
    }
  }

  Future<String> sendMessage(String message, List<CoachMessage> history) async {
    _validateConfiguration();

    try {
      final ragContext = await _buildRagContext(message);
      return await _callAiWithFallback(
        message: message,
        history: history,
        ragContext: ragContext,
      );
    } catch (e) {
      debugPrint('Coach generation failed: $e');
    }

    // Simulate realistic delay
    await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(700)));
    return _fallbackResponse(message);
  }

  Future<String> _callAiWithFallback({
    required String message,
    required List<CoachMessage> history,
    required _CoachRagContext ragContext,
  }) async {
    final errors = <String>[];

    for (final model in _models) {
      for (var attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          return await _callAi(
            message: message,
            history: history,
            model: model,
            ragContext: ragContext,
          );
        } catch (e) {
          errors.add('$model#${attempt + 1} -> $e');
          if (!_isRetryableError(e) || attempt >= _maxRetries - 1) {
            break;
          }
          await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
        }
      }
    }

    throw Exception('All free coach models failed: ${errors.join(' | ')}');
  }

  Future<String> _callAi({
    required String message,
    required List<CoachMessage> history,
    required String model,
    required _CoachRagContext ragContext,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');

    final recentHistory = history.length <= _recentHistoryLimit
        ? history
        : history.sublist(history.length - _recentHistoryLimit);

    final responseSchema = {
      'snapshot': '1-2 concise sentences',
      'problems': ['string'],
      'next_move': 'one concrete action',
      'tips': ['2-4 short bullets'],
      'patterns': ['data-backed observations'],
    };

    final messages = [
      {'role': 'system', 'content': _buildSystemPrompt(responseSchema)},
      {'role': 'system', 'content': _buildContextPrompt(ragContext)},
      ...recentHistory.map(
        (m) => {
          'role': m.role == 'ai' ? 'assistant' : 'user',
          'content': m.text,
        },
      ),
      {'role': 'user', 'content': message},
    ];

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            if (_baseUrl.contains('openrouter.ai'))
              'HTTP-Referer':
                  dotenv.env['COACH_HTTP_REFERER'] ?? 'http://localhost',
            if (_baseUrl.contains('openrouter.ai'))
              'X-Title':
                  dotenv.env['COACH_APP_TITLE'] ??
                  'Micro Skill Decay Detector - AI Coach',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.2,
            'max_tokens': 420,
            'top_p': 0.9,
            'messages': messages,
          }),
        )
        .timeout(Duration(seconds: _timeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = _extractApiErrorDetail(response.body);
      throw Exception(
        'Coach API status ${response.statusCode}${detail.isEmpty ? '' : ': $detail'}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception('Coach API returned no choices.');
    }

    final content = choices.first['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('Coach API returned empty content.');
    }

    return _normalizeCoachResponse(content.trim());
  }

  String _buildSystemPrompt(Map<String, dynamic> responseSchema) {
    return '''
You are an AI learning coach inside a skill retention app.

Use only the provided JSON context and recent chat history.
Be concise, practical, and evidence-based.

Return JSON only with exactly these keys:
${jsonEncode(responseSchema)}

Rules:
- No markdown fences.
- No extra keys.
- No prose outside JSON.
- If data is missing, say so briefly in the relevant field.
- Keep each value short.
- Prefer actionable coaching over explanation.
- Do not invent metrics not in context.

Field intent:
- snapshot: 1-2 sentence summary
- problems: 2-4 short items describing the main issues
- next_move: the single best action for today
- tips: 2-4 concise productivity or learning tips
- patterns: 2-5 data-backed observations
''';
  }

  String _buildContextPrompt(_CoachRagContext context) {
    return jsonEncode(context.toJson());
  }

  Future<_CoachRagContext> _buildRagContext(String userMessage) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _CoachRagContext(
        profile: {
          'uid': '',
          'name': 'Unknown',
          'email': 'Unknown',
          'skills_total': 0,
          'avg_mastery': 0,
          'stable_skills': 0,
          'moderate_skills': 0,
          'urgent_skills': 0,
          'consistency_7d': 0,
        },
        skills: const [],
        recentActivity: const {},
        quizTrends: const {},
        patterns: const ['No authenticated user.'],
      );
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final userDocFuture = userRef.get();
    final skillsFuture = userRef.collection('skills').limit(80).get();
    final practiceFuture = userRef
        .collection('practice_sessions')
        .orderBy('timestamp', descending: true)
        .limit(120)
        .get();
    final quizFuture = userRef
        .collection('quiz_results')
        .orderBy('timestamp', descending: true)
        .limit(120)
        .get();

    final userDoc = await userDocFuture;
    final skillsSnapshot = await skillsFuture;
    final practiceSnapshot = await practiceFuture;
    final quizSnapshot = await quizFuture;

    final userData = userDoc.data() ?? <String, dynamic>{};
    final skills = skillsSnapshot.docs.map((d) => d.data()).toList();
    final practices = practiceSnapshot.docs.map((d) => d.data()).toList();
    final quizzes = quizSnapshot.docs.map((d) => d.data()).toList();

    final now = DateTime.now();
    final skillsCount = skills.length;
    final avgMastery = skillsCount == 0
        ? 0.0
        : skills
                  .map((s) => _toDouble(s['mastery']))
                  .fold<double>(0.0, (a, b) => a + b) /
              skillsCount;

    final riskBuckets = _computeRiskBuckets(skills, now);
    final consistency = skillsCount == 0
        ? 0.0
        : (riskBuckets.stable / skillsCount).clamp(0.0, 1.0);

    final quizStats = _computeQuizStats(quizzes, now);
    final patterns = _derivePatterns(
      skills: skills,
      practices: practices,
      quizzes: quizzes,
      now: now,
    );

    final recentActivity = _buildRecentActivitySummary(
      practices: practices,
      quizzes: quizzes,
      now: now,
    );
    final topSkills = _rankRelevantSkills(
      skills,
      userMessage,
      now,
    ).take(_retrievedSkillLimit).toList();

    final profile = _buildProfileJson(
      user: user,
      userData: userData,
      skillsCount: skillsCount,
      avgMastery: avgMastery,
      riskBuckets: riskBuckets,
      consistency: consistency,
    );

    return _CoachRagContext(
      profile: profile,
      skills: topSkills.map((item) => item.toJson()).toList(),
      recentActivity: recentActivity,
      quizTrends: quizStats.toJson(),
      patterns: patterns,
    );
  }

  Map<String, dynamic> _buildProfileJson({
    required User user,
    required Map<String, dynamic> userData,
    required int skillsCount,
    required double avgMastery,
    required _RiskBuckets riskBuckets,
    required double consistency,
  }) {
    return {
      'uid': user.uid,
      'name': user.displayName ?? userData['display_name'] ?? 'Unknown',
      'email': user.email ?? userData['email'] ?? 'Unknown',
      'skills_total': skillsCount,
      'avg_mastery': double.parse(avgMastery.toStringAsFixed(1)),
      'stable_skills': riskBuckets.stable,
      'moderate_skills': riskBuckets.moderate,
      'urgent_skills': riskBuckets.urgent,
      'consistency_7d': double.parse((consistency * 100).toStringAsFixed(0)),
    };
  }

  Map<String, dynamic> _buildRecentActivitySummary({
    required List<Map<String, dynamic>> practices,
    required List<Map<String, dynamic>> quizzes,
    required DateTime now,
  }) {
    final practice7d = practices
        .map((p) => _toDateTime(p['timestamp']))
        .whereType<DateTime>()
        .where((t) => now.difference(t).inDays <= 7)
        .length;
    final practice30d = practices
        .map((p) => _toDateTime(p['timestamp']))
        .whereType<DateTime>()
        .where((t) => now.difference(t).inDays <= 30)
        .length;
    final quiz7d = quizzes
        .map((q) => _toDateTime(q['timestamp']))
        .whereType<DateTime>()
        .where((t) => now.difference(t).inDays <= 7)
        .length;
    final lastPractice = practices
        .map((p) => _toDateTime(p['timestamp']))
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (latest, item) =>
              latest == null || item.isAfter(latest) ? item : latest,
        );

    return {
      'practice_7d': practice7d,
      'practice_30d': practice30d,
      'quiz_7d': quiz7d,
      'last_practice_days': _daysSince(lastPractice, now),
    };
  }

  _RiskBuckets _computeRiskBuckets(
    List<Map<String, dynamic>> skills,
    DateTime now,
  ) {
    var stable = 0;
    var moderate = 0;
    var urgent = 0;

    for (final skill in skills) {
      final lastPracticed = _toDateTime(skill['lastPracticed']);
      final days = _daysSince(lastPracticed, now);
      if (days >= 10) {
        urgent++;
      } else if (days >= 5) {
        moderate++;
      } else {
        stable++;
      }
    }

    return _RiskBuckets(stable: stable, moderate: moderate, urgent: urgent);
  }

  int _countRecentPractices(
    List<Map<String, dynamic>> practices,
    DateTime now, {
    required int days,
  }) {
    return practices.where((p) {
      final t = _toDateTime(p['timestamp']);
      if (t == null) {
        return false;
      }
      return now.difference(t).inDays <= days;
    }).length;
  }

  _QuizStats _computeQuizStats(
    List<Map<String, dynamic>> quizzes,
    DateTime now,
  ) {
    final in30d = quizzes.where((q) {
      final t = _toDateTime(q['timestamp']);
      if (t == null) {
        return false;
      }
      return now.difference(t).inDays <= 30;
    }).toList();

    if (in30d.isEmpty) {
      return const _QuizStats(
        attempts30d: 0,
        avgPercent30d: 0,
        trend: 'no-data',
      );
    }

    final percents = in30d.map((q) {
      final score = _toDouble(q['score']);
      final total = _toDouble(q['totalQuestions']);
      if (total <= 0) {
        return 0.0;
      }
      return (score / total) * 100.0;
    }).toList();

    final avg = percents.fold<double>(0.0, (a, b) => a + b) / percents.length;

    final sorted = List<Map<String, dynamic>>.from(in30d)
      ..sort((a, b) {
        final ad =
            _toDateTime(a['timestamp']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd =
            _toDateTime(b['timestamp']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });

    final firstHalf = sorted.take((sorted.length / 2).ceil()).toList();
    final secondHalf = sorted.skip((sorted.length / 2).ceil()).toList();

    double avgPercent(List<Map<String, dynamic>> chunk) {
      if (chunk.isEmpty) {
        return 0;
      }
      final values = chunk.map((q) {
        final score = _toDouble(q['score']);
        final total = _toDouble(q['totalQuestions']);
        if (total <= 0) {
          return 0.0;
        }
        return (score / total) * 100.0;
      }).toList();
      return values.fold<double>(0.0, (a, b) => a + b) / values.length;
    }

    final first = avgPercent(firstHalf);
    final second = avgPercent(secondHalf);
    final delta = second - first;

    final trend = delta > 4
        ? 'improving'
        : (delta < -4 ? 'declining' : 'stable');

    return _QuizStats(
      attempts30d: in30d.length,
      avgPercent30d: avg,
      trend: trend,
    );
  }

  List<String> _derivePatterns({
    required List<Map<String, dynamic>> skills,
    required List<Map<String, dynamic>> practices,
    required List<Map<String, dynamic>> quizzes,
    required DateTime now,
  }) {
    final patterns = <String>[];

    if (skills.isEmpty) {
      patterns.add('No skills added yet.');
      return patterns;
    }

    final urgentSkills = skills.where((s) {
      final d = _daysSince(_toDateTime(s['lastPracticed']), now);
      return d >= 10;
    }).length;

    if (urgentSkills > 0) {
      patterns.add(
        '$urgentSkills skills are in high decay risk (10+ days inactive).',
      );
    }

    final masterySorted = List<Map<String, dynamic>>.from(skills)
      ..sort(
        (a, b) => _toDouble(a['mastery']).compareTo(_toDouble(b['mastery'])),
      );
    final weakest = masterySorted.take(3).map((s) {
      final name = '${s['name'] ?? 'Unknown'}';
      final mastery = _toDouble(s['mastery']).toStringAsFixed(0);
      return '$name ($mastery%)';
    }).toList();
    if (weakest.isNotEmpty) {
      patterns.add('Lowest mastery cluster: ${weakest.join(', ')}.');
    }

    final sessions7d = _countRecentPractices(practices, now, days: 7);
    if (sessions7d == 0) {
      patterns.add('No practice sessions in last 7 days.');
    } else if (sessions7d < 3) {
      patterns.add(
        'Practice frequency is low in the last 7 days ($sessions7d sessions).',
      );
    } else {
      patterns.add(
        'Practice frequency is active in last 7 days ($sessions7d sessions).',
      );
    }

    final quizStats = _computeQuizStats(quizzes, now);
    if (quizStats.attempts30d > 0) {
      patterns.add(
        'Quiz performance trend is ${quizStats.trend} (avg ${quizStats.avgPercent30d.toStringAsFixed(1)}%).',
      );
    }

    return patterns;
  }

  List<String> _keywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3)
        .toList();

    const stopwords = {
      'what',
      'should',
      'about',
      'with',
      'from',
      'your',
      'this',
      'that',
      'have',
      'will',
      'would',
      'could',
      'please',
      'help',
      'tips',
      'next',
      'move',
    };
    return words.where((w) => !stopwords.contains(w)).toSet().toList();
  }

  List<_RankedSkill> _rankRelevantSkills(
    List<Map<String, dynamic>> skills,
    String userMessage,
    DateTime now,
  ) {
    final tokens = _keywords(userMessage);
    final ranked = <_RankedSkill>[];

    for (final skill in skills) {
      final name = '${skill['name'] ?? ''}'.trim();
      final category = '${skill['category'] ?? ''}'.trim();
      final level = '${skill['difficultyLevel'] ?? ''}'.trim();
      final notes = '${skill['notes'] ?? ''}'.trim();
      final mastery = _toDouble(skill['mastery']);
      final lastPracticed = _toDateTime(skill['lastPracticed']);
      final daysInactive = _daysSince(lastPracticed, now);
      final weakTopics = (skill['weakTopics'] is List)
          ? List<String>.from((skill['weakTopics'] as List).map((e) => '$e'))
          : <String>[];

      final hay = '$name $category $level $notes ${weakTopics.join(' ')}'
          .toLowerCase();
      var keywordScore = 0.0;
      for (final token in tokens) {
        if (hay.contains(token)) {
          keywordScore += token.length >= 6 ? 2.0 : 1.0;
        }
      }

      final lowMasteryScore = (100 - mastery) / 20.0;
      final inactivityScore = min(daysInactive / 3.0, 8.0);
      final weakTopicScore =
          weakTopics.any((t) => tokens.contains(t.toLowerCase())) ? 2.5 : 0.0;
      final recencyPenalty = daysInactive <= 2 ? -1.0 : 0.0;

      ranked.add(
        _RankedSkill(
          score:
              keywordScore +
              lowMasteryScore +
              inactivityScore +
              weakTopicScore +
              recencyPenalty,
          skill: {
            'name': name,
            'category': category,
            'difficulty': level,
            'mastery': double.parse(mastery.toStringAsFixed(1)),
            'decay_days': daysInactive,
            'weak_topics': weakTopics.take(4).toList(),
            'notes': _truncate(notes, 80),
            'keyword_hit': keywordScore > 0,
          },
        ),
      );
    }

    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
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
      // Best effort only.
    }
    final compact = responseBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '';
    }
    return compact.length > 180 ? '${compact.substring(0, 180)}...' : compact;
  }

  bool _isRetryableError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('timeout') ||
        text.contains('socket') ||
        text.contains('failed host lookup') ||
        text.contains('status 429') ||
        text.contains('status 500') ||
        text.contains('status 502') ||
        text.contains('status 503') ||
        text.contains('status 504');
  }

  String _normalizeCoachResponse(String content) {
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json|```'), '').trim();
    }

    final parsed = _extractJsonObject(cleaned);
    if (parsed is Map<String, dynamic>) {
      return jsonEncode({
        'snapshot': _stringField(parsed['snapshot']),
        'problems': _stringList(parsed['problems']),
        'next_move': _stringField(parsed['next_move']),
        'tips': _stringList(parsed['tips']),
        'patterns': _stringList(parsed['patterns']),
      });
    }

    return jsonEncode({
      'snapshot': cleaned,
      'problems': <String>[],
      'next_move': '',
      'tips': <String>[],
      'patterns': <String>[],
    });
  }

  dynamic _extractJsonObject(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        return null;
      }
      return jsonDecode(text.substring(start, end + 1));
    } catch (_) {
      return null;
    }
  }

  String _stringField(dynamic value) {
    final text = '$value'.trim();
    return text == 'null' ? '' : text;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => _stringField(e))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final text = _stringField(value);
    if (text.isEmpty) {
      return const [];
    }
    return [text];
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  int _daysSince(DateTime? dt, DateTime now) {
    if (dt == null) {
      return 999;
    }
    return now.difference(dt).inDays;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0.0;
  }

  String _truncate(String text, int max) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= max) {
      return cleaned;
    }
    return '${cleaned.substring(0, max)}...';
  }

  String _fallbackResponse(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('practice') || msg.contains('today')) {
      return jsonEncode({
        'snapshot':
            'Your current data points to urgent skills that need immediate attention.',
        'problems': [
          'Some skills have likely decayed from inactivity.',
          'A short focused session will give the fastest return.',
        ],
        'next_move': 'Practice one urgent skill for 10 minutes today.',
        'tips': [
          'Start with recall before rereading notes.',
          'Keep the session short to reduce friction.',
        ],
        'patterns': ['The highest-risk skill should be addressed first.'],
      });
    }
    if (msg.contains('retention') ||
        msg.contains('remember') ||
        msg.contains('forget')) {
      return jsonEncode({
        'snapshot':
            'Retention improves fastest when you revisit content before it disappears.',
        'problems': ['Forgetting grows when review is delayed too long.'],
        'next_move': 'Use spaced repetition with short recall checks.',
        'tips': [
          'Review at 1, 3, 7, and 14 days.',
          'Test yourself instead of rereading.',
          'Mix related skills in one session.',
        ],
        'patterns': [
          'Your app is already designed around retention-friendly practice.',
        ],
      });
    }
    if (msg.contains('routine') ||
        msg.contains('schedule') ||
        msg.contains('plan')) {
      return jsonEncode({
        'snapshot': 'A short daily routine beats occasional long sessions.',
        'problems': ['Large sessions are harder to sustain consistently.'],
        'next_move': 'Split practice into a 10-15-5 minute daily cycle.',
        'tips': [
          'Do recall first thing.',
          'Practice one skill at a time.',
          'End with a quick reflection.',
        ],
        'patterns': ['Consistency matters more than duration.'],
      });
    }
    if (msg.contains('doing') ||
        msg.contains('progress') ||
        msg.contains('overall')) {
      return jsonEncode({
        'snapshot':
            'You are making solid progress, especially where practice is recent.',
        'problems': ['Urgent skills may still be lagging behind.'],
        'next_move':
            'Keep the streak alive and target the highest-risk skill next.',
        'tips': [
          'Protect momentum with a daily check-in.',
          'Move one urgent skill into the stable range.',
        ],
        'patterns': ['Recent practice is a strong retention signal.'],
      });
    }
    if (msg.contains('motivation') ||
        msg.contains('difficult') ||
        msg.contains('hard') ||
        msg.contains('struggle')) {
      return jsonEncode({
        'snapshot':
            'Struggle is often a sign that the skill is in the right growth zone.',
        'problems': [
          'The skill may be too broad or too hard to attack at once.',
        ],
        'next_move':
            'Break the skill into 3-5 smaller sub-skills and practice one.',
        'tips': [
          'Use micro-goals.',
          'Track small wins.',
          'Keep sessions short when motivation is low.',
        ],
        'patterns': ['Difficulty often improves when the task is decomposed.'],
      });
    }
    if (msg.contains('tip') ||
        msg.contains('improve') ||
        msg.contains('better')) {
      return jsonEncode({
        'snapshot':
            'These habits usually improve learning speed and retention.',
        'problems': ['Passive rereading is less effective than active recall.'],
        'next_move': 'Apply retrieval practice to one skill today.',
        'tips': [
          'Teach the concept in your own words.',
          'Use a 25/5 focus cycle.',
          'Sleep well after practice to consolidate memory.',
        ],
        'patterns': ['Active recall and spacing give the biggest gains.'],
      });
    }

    // Generic thoughtful response
    final responses = [
      {
        'snapshot':
            'That is a useful question, and the answer depends on your current pattern.',
        'problems': [
          'The biggest gap is usually the skill with the longest inactivity.',
        ],
        'next_move':
            'Pick the highest-risk skill and do a quick recall session today.',
        'tips': [
          'Keep the action small enough to start immediately.',
          'Use the app data before deciding what to practice.',
        ],
        'patterns': [
          'Small consistent sessions beat occasional long sessions.',
        ],
      },
      {
        'snapshot':
            'Your coaching signal is strongest when practice, mastery, and inactivity are read together.',
        'problems': [
          'Streaks can hide weak spots if low-mastery skills are ignored.',
        ],
        'next_move':
            'Review the skill with the lowest mastery and highest inactivity.',
        'tips': [
          'Compare recent practice with decay risk.',
          'Use one focused skill per session.',
        ],
        'patterns': ['High mastery with low recency still needs maintenance.'],
      },
    ];
    return jsonEncode(responses[Random().nextInt(responses.length)]);
  }
}

class _CoachRagContext {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> skills;
  final Map<String, dynamic> recentActivity;
  final Map<String, dynamic> quizTrends;
  final List<String> patterns;

  const _CoachRagContext({
    required this.profile,
    required this.skills,
    required this.recentActivity,
    required this.quizTrends,
    required this.patterns,
  });

  Map<String, dynamic> toJson() {
    return {
      'profile': profile,
      'skills': skills,
      'recent_activity': recentActivity,
      'quiz_trends': quizTrends,
      'patterns': patterns,
    };
  }
}

class _RiskBuckets {
  final int stable;
  final int moderate;
  final int urgent;

  const _RiskBuckets({
    required this.stable,
    required this.moderate,
    required this.urgent,
  });
}

class _QuizStats {
  final int attempts30d;
  final double avgPercent30d;
  final String trend;

  const _QuizStats({
    required this.attempts30d,
    required this.avgPercent30d,
    required this.trend,
  });

  Map<String, dynamic> toJson() {
    return {
      'attempts_30d': attempts30d,
      'avg_percent_30d': double.parse(avgPercent30d.toStringAsFixed(1)),
      'trend': trend,
    };
  }
}

class _RankedSkill {
  final double score;
  final Map<String, dynamic> skill;

  const _RankedSkill({required this.score, required this.skill});

  Map<String, dynamic> toJson() => skill;
}
