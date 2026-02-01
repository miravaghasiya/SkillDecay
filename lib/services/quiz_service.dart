import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizService {
  // Use 10.0.2.2 for Android emulator to access localhost
  // Use localhost for iOS simulator or web
  // For physical device, use your machine's IP
  static const String baseUrl = 'http://10.0.2.2:3000'; 

  Future<List<Map<String, dynamic>>> generateQuiz({
    required String skillId,
    required String skillTitle,
    required String category,
    required String userLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'skillId': skillId,
          'skillTitle': skillTitle,
          'category': category,
          'userLevel': userLevel,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to generate quiz: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating quiz: $e');
    }
  }

  Future<void> saveSession({
    required String userId,
    required String skillId,
    required int score,
    required int totalQuestions,
    required List<Map<String, dynamic>> questions,
    required Map<int, int> userAnswers,
    required String difficultyLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'skillId': skillId,
          'score': score,
          'totalQuestions': totalQuestions,
          'questions': questions,
          'userAnswers': userAnswers.map((k, v) => MapEntry(k.toString(), v)), // Convert int keys to string for JSON
          'difficultyLevel': difficultyLevel,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save session: ${response.body}');
      }
    } catch (e) {
      print('Error saving session: $e');
    }
  }
}
