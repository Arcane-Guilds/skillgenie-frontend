class EvaluationQuestion {
  final int id;
  final String question;
  final String type;
  final List<String> options;
  final String correctAnswer;
  final String? codeTemplate;
  final String? codeSnippet;
  final String? language;
  final String testId;
  final String userId;

  EvaluationQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.codeTemplate,
    this.codeSnippet,
    this.language,
    required this.testId,
    required this.userId,
  });

  factory EvaluationQuestion.fromJson(Map<String, dynamic> json) {
    return EvaluationQuestion(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      type: json['type'] ?? 'multiple-choice',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      codeTemplate: json['codeTemplate'],
      codeSnippet: json['codeSnippet'],
      language: json['language'],
      testId: json['testId'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  bool get isProgramming => type == 'programming' || type == 'code';
}