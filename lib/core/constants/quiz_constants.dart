import 'api_constants.dart';

class QuizConstants{
  static String get fetchQuizQuestions => '${ApiConstants.baseUrl}/quiz/questions';
  static String get submitQuiz => '${ApiConstants.baseUrl}/quiz/submit';
  static String get generateEvaluationTest => '${ApiConstants.baseUrl}/quiz/evaluation/generate';
  static String get submitEvaluation => '${ApiConstants.baseUrl}/quiz/evaluation/submit';
  }