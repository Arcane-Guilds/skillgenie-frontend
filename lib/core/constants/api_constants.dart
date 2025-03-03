class ApiConstants {
  static const String baseUrl = 'https://f474-102-106-28-111.ngrok-free.app';

  static const String signup = '$baseUrl/auth/signup';
  static const String signin = '$baseUrl/auth/signin';
  static const String forgot_password = '$baseUrl/auth/forgot-password';
  static const String verify_otp = '$baseUrl/auth/verify-otp';
  static const String reset_password = '$baseUrl/auth/reset-password';

  // Add quiz-related URLs
  static const String fetchQuizQuestions = '$baseUrl/quiz/questions';
  static const String submitQuiz = '$baseUrl/quiz/submit';
  static const String generateEvaluationTest =
      '$baseUrl/quiz/evaluation/generate';
  static const String submitEvaluation = '$baseUrl/quiz/evaluation/submit';
}
