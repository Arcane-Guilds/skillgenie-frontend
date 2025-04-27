import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Support multiple environments with a fallback to localhost
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
}

class AnalyticsConstants {
  static String get userProgress => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/progress
  static String get strengthsWeaknesses => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/strengths-weaknesses
  static String get engagement => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/engagement
  static String get recommendations => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/recommendations
}
