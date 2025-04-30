import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {

  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://95d0-197-15-234-88.ngrok-free.app ';


}

class AnalyticsConstants {
  static String get userProgress => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/progress
  static String get strengthsWeaknesses => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/strengths-weaknesses
  static String get engagement => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/engagement
  static String get recommendations => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/recommendations
}
