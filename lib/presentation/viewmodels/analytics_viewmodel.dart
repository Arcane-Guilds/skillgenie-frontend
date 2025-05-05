import 'package:flutter/material.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/analytics_repository.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsRepository _repository;

  UserProgress? userProgress;
  StrengthsWeaknesses? strengthsWeaknesses;
  Engagement? engagement;
  Recommendations? recommendations;

  bool isLoading = false;
  String? errorMessage;

  AnalyticsViewModel({required AnalyticsRepository repository}) : _repository = repository;

  Future<void> fetchAll(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getUserProgress(userId),
        _repository.getStrengthsWeaknesses(userId),
        _repository.getEngagement(userId),
        _repository.getRecommendations(userId),
      ]);
      userProgress = results[0] as UserProgress;
      strengthsWeaknesses = results[1] as StrengthsWeaknesses;
      engagement = results[2] as Engagement;
      recommendations = results[3] as Recommendations;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}