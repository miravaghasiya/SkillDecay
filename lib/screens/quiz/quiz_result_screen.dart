import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final List<QuizQuestion> questions;
  final Map<int, int> userAnswers; // questionIndex -> selectedOptionIndex

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalQuestions > 0 ? (score / totalQuestions * 100).toInt() : 0;
    Color scoreColor = percentage >= 80 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quiz Results', style: TextStyle(color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Column(
                children: [
                  Text(
                    '$score / $totalQuestions',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 16,
                      color: scoreColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Review Answers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final question = questions[index];
                final correctIndex = question.correctAnswerIndex;
                final userIndex = userAnswers[index] ?? -1;
                final isCorrect = userIndex == correctIndex;
                final options = question.options;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                    color: isCorrect ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q${index + 1}: ${question.question}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...options.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final text = entry.value;
                        final isCorrectOption = idx == correctIndex;
                        final isUserSelection = idx == userIndex;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                isCorrectOption ? Icons.check_circle : (isUserSelection ? Icons.cancel : Icons.radio_button_unchecked),
                                size: 18,
                                color: isCorrectOption ? Colors.green : (isUserSelection ? Colors.red : Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: isCorrectOption ? Colors.green : (isUserSelection ? Colors.red : const Color(0xFF1E293B)),
                                    fontWeight: isCorrectOption || isUserSelection ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (question.explanation.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          'Explanation: ${question.explanation}',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Back to Skill', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
