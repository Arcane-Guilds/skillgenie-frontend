import '../models/analytics_model.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepository {
  final AnalyticsRemoteDataSource _remoteDataSource;

  AnalyticsRepository({required AnalyticsRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  Future<UserProgress> getUserProgress(String userId) => _remoteDataSource.getUserProgress(userId);
  Future<StrengthsWeaknesses> getStrengthsWeaknesses(String userId) => _remoteDataSource.getStrengthsWeaknesses(userId);
  Future<Engagement> getEngagement(String userId) => _remoteDataSource.getEngagement(userId);
  Future<Recommendations> getRecommendations(String userId) => _remoteDataSource.getRecommendations(userId);
}