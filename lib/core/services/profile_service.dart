import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:frontend/data/repositories/auth_repository.dart';
import '../../data/models/api_exception.dart';
import '../../data/models/user_model.dart';


class ProfileService {
  final http.Client _client;
  final AuthRepository _authService;
  final String _baseUrl;

  ProfileService({
    required http.Client client,
    required AuthRepository authService,
    required String baseUrl,
  })  : _client = client,
        _authService = authService,
        _baseUrl = baseUrl;

  Future<User> fetchUserProfile() async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Map the MongoDB _id to id for the User model
        data['id'] = data['_id'];
        return User.fromJson(data);
      } else {
        throw ApiException(
          'Failed to fetch profile',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      print('Error fetching profile: $e'); // Add this for debugging
      throw ApiException(
        'Network error while fetching profile',
        500,
        e.toString(),
      );
    }
  }

  Future<void> updateUserProfile(User profile) async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      final response = await _client.patch( // Fix: Change to PATCH
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode(profile.toJson()),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update profile',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      throw ApiException(
        'Network error while updating profile',
        500,
        e.toString(),
      );
    }
  }

  Future<void> updateBio(String bio) async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      final response = await _client.patch( // Fix: Change to PATCH user/profile
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'bio': bio}),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update bio',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      throw ApiException(
        'Network error while updating bio',
        500,
        e.toString(),
      );
    }
  }

  Future<void> deleteUserProfile() async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      final response = await _client.delete(
        Uri.parse('$_baseUrl/user/profile'), // Fix: Correct endpoint
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to delete profile',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      throw ApiException(
        'Network error while deleting profile',
        500,
        e.toString(),
      );
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final tokens = await _authService.getTokens();
      final response = await _client.put(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Authorization': 'Bearer ${tokens!.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to change password',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      throw ApiException(
        'Network error while changing password',
        500,
        e.toString(),
      );
    }
  }
}
