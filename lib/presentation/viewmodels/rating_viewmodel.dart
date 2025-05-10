import 'package:flutter/material.dart';
import '../../core/services/rating_service.dart';
import '../../data/models/rating_model.dart';
import 'auth/auth_viewmodel.dart';

class RatingViewModel extends ChangeNotifier {
  final RatingService _ratingService;
  final AuthViewModel _authViewModel;

  Rating? _userRating;
  bool _isLoading = false;
  String? _error;
  double _averageRating = 0;

  RatingViewModel(this._ratingService, this._authViewModel);

  Rating? get userRating => _userRating;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get averageRating => _averageRating;

  Future<void> submitRating(int stars, String? comment) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final tokens = _authViewModel.tokens;
      if (tokens == null) {
        throw Exception('You must be logged in to submit a rating');
      }

      _userRating =
          await _ratingService.createRating(tokens.accessToken, stars, comment);

      // Update average rating after successful submission
      if (_userRating != null) {
        _averageRating = stars
            .toDouble(); // Simplified for now since we're not showing all ratings
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
