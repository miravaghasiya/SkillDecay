import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/skill.dart';
import '../../services/quiz_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Skill skill;

  const QuizScreen({super.key, required this.skill});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  String? _error;
  
  Timer? _timer;
  static const int _questionDuration = 10; // Changed to 10 seconds
  int _timeLeft = _questionDuration;
  bool _answered = false;
  int? _selectedOptionIndex;
  
  // Track user answers: questionIndex -> selectedOptionIndex
  final Map<int, int> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      final questions = await _quizService.generateQuiz(
        skillId: widget.skill.id!, // Assuming ID exists
        skillTitle: widget.skill.name,
        category: widget.skill.category,
        userLevel: widget.skill.difficultyLevel,
      );
      
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _timeLeft = _questionDuration;
        _answered = false;
        _selectedOptionIndex = null;
      });
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) {
          setState(() {
            _timeLeft--;
          });
        }
      } else {
        _timer?.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    if (!_answered) {
      _submitAnswer(-1); // -1 means Time's Up / No Answer
    }
  }

  void _submitAnswer(int optionIndex) {
    if (_answered) return;
    
    _timer?.cancel();
    _userAnswers[_currentQuestionIndex] = optionIndex;
    
    if (mounted) {
      setState(() {
        _answered = true;
        _selectedOptionIndex = optionIndex;
      });
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    if (optionIndex == currentQuestion['correctIndex']) {
      _score++;
    }

    // Wait and go to next
    Future.delayed(const Duration(seconds: 1), () { // Faster transition
      if (!mounted) return;
      
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
        _startTimer();
      } else {
        _finishQuiz();
      }
    });
  }

  Future<void> _finishQuiz() async {
    // Save session in background
    _quizService.saveSession(
      userId: widget.skill.userId,
      skillId: widget.skill.id!,
      score: _score,
      totalQuestions: _questions.length,
      difficultyLevel: widget.skill.difficultyLevel,
      questions: _questions,
      userAnswers: _userAnswers,
    );

    // Navigate to results
    if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
            builder: (_) => QuizResultScreen(
                score: _score,
                totalQuestions: _questions.length,
                questions: _questions,
                userAnswers: _userAnswers,
            ),
            ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Practice: ${widget.skill.name}', style: const TextStyle(color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          )
      );
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions generated.'));
    }

    final question = _questions[_currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${_currentQuestionIndex + 1}/${_questions.length}",
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeLeft < 4 ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer, 
                      size: 16, 
                      color: _timeLeft < 4 ? Colors.red : const Color(0xFF64748B)
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$_timeLeft s", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _timeLeft < 4 ? Colors.red : const Color(0xFF64748B)
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            question['question'],
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final options = question['options'] as List;
                return _buildOptionButton(index, options[index], question['correctIndex']);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String text, int correctIndex) {
    Color borderColor = Colors.grey[200]!;
    Color backgroundColor = Colors.white;
    Color textColor = const Color(0xFF1E293B);
    
    // Show correct/incorrect selection after answering
    if (_answered) {
        if (index == correctIndex) {
            borderColor = const Color(0xFF10B981);
            backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
            textColor = const Color(0xFF10B981);
        } else if (index == _selectedOptionIndex) {
            borderColor = const Color(0xFFEF4444);
            backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
            textColor = const Color(0xFFEF4444);
        }
    }

    return InkWell(
      onTap: _answered ? null : () => _submitAnswer(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _answered && (index == correctIndex || index == _selectedOptionIndex) 
                    ? borderColor 
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _answered && (index == correctIndex || index == _selectedOptionIndex)
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
