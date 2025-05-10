import '../../data/models/rating_model.dart';
import '../../data/datasources/api_client.dart';

class RatingService {
  final ApiClient _apiClient;
  final String _baseUrl = '/ratings';

  RatingService(this._apiClient);

  Future<Rating> createRating(
      String accessToken, int stars, String? comment) async {
    _apiClient.addAuthenticationToken(accessToken);
    try {
      final response = await _apiClient.postRequest(_baseUrl, {
        'stars': stars,
        'comment': comment,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Rating.fromJson(response.data);
      } else {
        throw Exception('Failed to create rating: ${response.data}');
      }
    } finally {
      _apiClient.removeAuthenticationToken();
    }
  }
}
