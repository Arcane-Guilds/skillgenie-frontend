import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_achievement_model.dart';
import '../../core/constants/api_constants.dart';

class AchievementRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Future<List<UserAchievement>> fetchUserAchievements(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/achievements/user/$userId'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => UserAchievement.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load achievements');
    }
  }
}
