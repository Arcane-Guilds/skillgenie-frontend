import 'api_constants.dart';

class AnalyticsConstants {
  static String get userProgress => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/progress
  static String get strengthsWeaknesses => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/strengths-weaknesses
  static String get engagement => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/engagement
  static String get recommendations => '${ApiConstants.baseUrl}/analytics/user'; // + /:id/recommendations
}