class EvaluationQuestion {
  final String question;
  final String type;
  final List<String> options;
  final String correctAnswer;
  final String? codeTemplate;
  final String testId; // Ensure this is included
  final String userId; // Ensure this is included

  EvaluationQuestion({
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.codeTemplate,
    required this.testId,
    required this.userId,
  });

  factory EvaluationQuestion.fromJson(Map<String, dynamic> json) {
    return EvaluationQuestion(
      question: json['question'] ?? '',
      type: json['type'] ?? 'multiple-choice',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      codeTemplate: json['codeTemplate'],
      testId: json['testId'] ?? '', // Ensure this is populated
      userId: json['userId'] ?? '', // Ensure this is populated
    );
  }

  bool get isProgramming => type == 'programming';
}