class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String difficulty;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.difficulty,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] is List)
        ? List<String>.from((json['options'] as List).map((e) => '$e'))
        : <String>[];
    final normalizedOptions = _normalizeOptions(rawOptions);

    final correctIndex = _resolveCorrectIndex(json, normalizedOptions);

    return QuestionModel(
      id: '${json['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      question: '${json['question'] ?? ''}'.trim(),
      options: normalizedOptions,
      correctAnswerIndex: correctIndex,
      explanation: '${json['explanation'] ?? ''}'.trim(),
      difficulty: '${json['difficulty'] ?? json['userLevel'] ?? 'intermediate'}'
          .toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  static List<String> _normalizeOptions(List<String> options) {
    final clean = options
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    if (clean.length >= 4) {
      return clean.take(4).toList();
    }

    final result = List<String>.from(clean);
    while (result.length < 4) {
      result.add('Option ${result.length + 1}');
    }
    return result;
  }

  static int _resolveCorrectIndex(
    Map<String, dynamic> json,
    List<String> options,
  ) {
    final dynamic indexLike =
        json['correctIndex'] ??
        json['correctAnswerIndex'] ??
        json['correct_answer_index'];

    if (indexLike is int && indexLike >= 0 && indexLike < options.length) {
      return indexLike;
    }

    final answerText =
        '${json['correctAnswer'] ?? json['correct_answer'] ?? ''}'.trim();
    if (answerText.isNotEmpty) {
      final idx = options.indexWhere(
        (opt) => opt.toLowerCase() == answerText.toLowerCase(),
      );
      if (idx >= 0) {
        return idx;
      }
    }

    return 0;
  }
}
