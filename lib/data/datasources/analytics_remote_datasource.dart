import '../models/analytics_model.dart';
import '../models/api_exception.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/api_constants.dart';

class AnalyticsRemoteDataSource {
  final ApiClient _apiClient;

  AnalyticsRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserProgress> getUserProgress(String userId) async {
    final endpoint = '${AnalyticsConstants.userProgress}/$userId/progress';
    final response = await _apiClient.getData(endpoint);
    if (response.statusCode == 200) {
      return UserProgress.fromJson(response.data);
    } else {
      throw ApiException('Failed to fetch user progress', response.statusCode ?? 500, response.data.toString());
    }
  }

  Future<StrengthsWeaknesses> getStrengthsWeaknesses(String userId) async {
    final endpoint = '${AnalyticsConstants.strengthsWeaknesses}/$userId/strengths-weaknesses';
    final response = await _apiClient.getData(endpoint);
    if (response.statusCode == 200) {
      return StrengthsWeaknesses.fromJson(response.data);
    } else {
      throw ApiException('Failed to fetch strengths/weaknesses', response.statusCode ?? 500, response.data.toString());
    }
  }

  Future<Engagement> getEngagement(String userId) async {
    final endpoint = '${AnalyticsConstants.engagement}/$userId/engagement';
    final response = await _apiClient.getData(endpoint);
    if (response.statusCode == 200) {
      return Engagement.fromJson(response.data);
    } else {
      throw ApiException('Failed to fetch engagement', response.statusCode ?? 500, response.data.toString());
    }
  }

  Future<Recommendations> getRecommendations(String userId) async {
    final endpoint = '${AnalyticsConstants.recommendations}/$userId/recommendations';
    final response = await _apiClient.getData(endpoint);
    if (response.statusCode == 200) {
      return Recommendations.fromJson(response.data);
    } else {
      throw ApiException('Failed to fetch recommendations', response.statusCode ?? 500, response.data.toString());
    }
  }
} 