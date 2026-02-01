import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;
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
    final percentage = (score / totalQuestions * 100).toInt();
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
                final correctIndex = question['correctIndex'] as int;
                final userIndex = userAnswers[index] ?? -1;
                final isCorrect = userIndex == correctIndex;
                final options = question['options'] as List;

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
                        'Q${index + 1}: ${question['question']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(options.length, (optIndex) {
                        final isSelected = userIndex == optIndex;
                        final isAnswer = correctIndex == optIndex;
                        
                        Color? textColor;
                        FontWeight? fontWeight;
                        
                        if (isAnswer) {
                          textColor = Colors.green[700];
                          fontWeight = FontWeight.bold;
                        } else if (isSelected && !isCorrect) {
                          textColor = Colors.red[700];
                          fontWeight = FontWeight.bold;
                        } else {
                          textColor = const Color(0xFF64748B);
                          fontWeight = FontWeight.normal;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isAnswer 
                                    ? Icons.check_circle 
                                    : (isSelected ? Icons.cancel : Icons.circle_outlined),
                                size: 16,
                                color: textColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  options[optIndex],
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: fontWeight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
