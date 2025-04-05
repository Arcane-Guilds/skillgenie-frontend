// lib/models/quiz_question.dart
class QuizQuestion {
  final int id;
  final String question;
  final String type;
  final List<String> options;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      type: json['type'],
      options: List<String>.from(json['options']),
    );
  }
}
