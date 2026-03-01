import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/quiz_question.dart';

class QuizService {
  // Use 10.0.2.2 for Android emulator to access localhost on host machine
  // Use localhost for iOS simulator or web
  final String _baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

  // In-memory cache for quiz questions: Map<skillId, List<QuizQuestion>>
  static final Map<String, List<QuizQuestion>> _cache = {};

  Future<List<QuizQuestion>> generateQuizBatch({
    required String skillId,
    required String skillTitle,
    required String category,
    required String userLevel, // Beginner, Intermediate, Advanced
    required double mastery,   // 0-100
    List<String> previousQuestions = const [],
  }) async {
    // 1. Check cache first
    if (_cache.containsKey(skillId) && _cache[skillId]!.isNotEmpty) {
      return _cache[skillId]!.take(5).toList();
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-quiz'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'skillId': skillId,
          'skillTitle': skillTitle,
          'category': category,
          'userLevel': userLevel,
          'mastery': mastery,
          'previousQuestions': previousQuestions,
        }),
      ).timeout(const Duration(seconds: 40)); // Increased to 40 seconds

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        final List<QuizQuestion> questions = data
            .map((q) => QuizQuestion.fromJson(q))
            .toList();

        // 2. Update Cache
        if (questions.isNotEmpty) {
          _cache[skillId] = questions;
        }

        return questions;
      } else {
        throw Exception('Backend failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error generating quiz from backend: $e');
      throw Exception('Error generating quiz: $e');
    }
  }

  // Clear cache for a specific skill (e.g., after quiz completion)
  void clearCache(String skillId) {
    _cache.remove(skillId);
  }

  Future<void> saveSession({
    required String userId,
    required String skillId,
    required int score,
    required int totalQuestions,
    required List<QuizQuestion> questions,
    required Map<int, int> userAnswers,
    required String difficultyLevel,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/save-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'skillId': skillId,
          'score': score,
          'totalQuestions': totalQuestions,
          'questions': questions.map((q) => q.toJson()).toList(),
          'userAnswers': userAnswers.map((k, v) => MapEntry(k.toString(), v)),
          'difficultyLevel': difficultyLevel,
        }),
      );
    } catch (e) {
      print('Error saving quiz session to backend: $e');
    }
  }
}
