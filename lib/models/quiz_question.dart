import 'question_model.dart';

@Deprecated('Use QuestionModel from question_model.dart')
class QuizQuestion extends QuestionModel {
  QuizQuestion({
    required super.id,
    required super.question,
    required super.options,
    required super.correctAnswerIndex,
    required super.explanation,
    required super.difficulty,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final model = QuestionModel.fromJson(json);
    return QuizQuestion(
      id: model.id,
      question: model.question,
      options: model.options,
      correctAnswerIndex: model.correctAnswerIndex,
      explanation: model.explanation,
      difficulty: model.difficulty,
    );
  }
}
