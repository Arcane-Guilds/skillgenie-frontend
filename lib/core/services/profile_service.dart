import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skillGenie/data/repositories/auth_repository.dart';
import '../../data/models/api_exception.dart';
import '../../data/models/user_model.dart';
import '../constants/cloudinary_constants.dart';

class ProfileService {
  final http.Client _client;
  final AuthRepository _authService;
  final String _baseUrl;
  static const String _profileCacheKey = 'cached_user_profile';
  final SharedPreferences _prefs;

  ProfileService({
    required http.Client client,
    required AuthRepository authService,
    required String baseUrl,
    required SharedPreferences prefs,
  })  : _client = client,
        _authService = authService,
        _baseUrl = baseUrl,
        _prefs = prefs;

  Future<User> fetchUserProfile() async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }

      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/user/profile'),
          headers: {
            'Authorization': 'Bearer ${tokens.accessToken}',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          data['id'] = data['_id'];
          final user = User.fromJson(data);

          // Cache the profile
          await _cacheProfile(user);

          return user;
        } else {
          throw ApiException(
            'Failed to fetch profile',
            response.statusCode,
            response.body,
          );
        }
      } catch (e) {
        // Try to return cached profile if network request fails
        final cachedUser = await getCachedProfile();
        if (cachedUser != null) {
          return cachedUser;
        }
        throw ApiException(
          'Network error while fetching profile',
          500,
          e.toString(),
        );
      }
    } catch (e) {
      log('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<void> _cacheProfile(User profile) async {
    try {
      await _prefs.setString(_profileCacheKey, json.encode(profile.toJson()));
    } catch (e) {
      log('Error caching profile: $e');
    }
  }

  Future<User?> getCachedProfile() async {
    try {
      final cachedData = _prefs.getString(_profileCacheKey);
      if (cachedData != null) {
        final userData = json.decode(cachedData);
        return User.fromJson(userData);
      }
    } catch (e) {
      log('Error reading cached profile: $e');
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      await _prefs.remove(_profileCacheKey);
    } catch (e) {
      log('Error clearing profile cache: $e');
    }
  }

  Future<void> updateUserProfile(User profile) async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      final response = await _client.patch(
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
      final response = await _client.patch(
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
        Uri.parse('$_baseUrl/user/profile'),
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
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }

      // Log the request for debugging
      log('Sending password change request to: $_baseUrl/auth/change-password');

      final response = await _client.put(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      // Log the response status for debugging
      log('Password change response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Password changed successfully
        log('Password changed successfully');

        // Check if the response contains new tokens
        try {
          final responseData = json.decode(response.body);
          if (responseData.containsKey('tokens')) {
            // Update tokens if provided in the response
            log('New tokens received after password change');
            await _authService.saveTokens(responseData['tokens']);
          }
        } catch (e) {
          log('No new tokens in response: $e');
        }
      } else if (response.statusCode == 401) {
        throw ApiException(
          'Current password is incorrect',
          response.statusCode,
          response.body,
        );
      } else {
        throw ApiException(
          'Failed to change password',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while changing password',
        500,
        e.toString(),
      );
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }

      // Log the request for debugging
      log('Sending profile image update request to: $_baseUrl/user/profile');

      final response = await _client.patch(
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'avatar': imageUrl,
        }),
      );

      // Log the response status for debugging
      log('Profile image update response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update profile image',
          response.statusCode,
          response.body,
        );
      }

      // Update the cached profile with the new image URL
      final cachedProfile = await getCachedProfile();
      if (cachedProfile != null) {
        final updatedProfile = cachedProfile.copyWith(avatar: imageUrl);
        await _cacheProfile(updatedProfile);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while updating profile image',
        500,
        e.toString(),
      );
    }
  }

  /// Upload profile image directly to Cloudinary via the backend
  Future<String?> uploadProfileImageToCloudinary(
      http.MultipartFile imageFile,
      {Function(double)? onProgress}
      ) async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }

      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${CloudinaryConstants.uploadEndpoint}'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';

      // Add the file to the request
      request.files.add(imageFile);

      // Send the request with progress tracking
      final streamedResponse = await request.send();

      // Track upload progress if callback provided
      if (onProgress != null) {
        int total = imageFile.length;
        int received = 0;

        streamedResponse.stream.listen((List<int> chunk) {
          received += chunk.length;
          final progress = received / total;
          onProgress(progress.clamp(0.0, 1.0));
        });
      }

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Parse the response to get the Cloudinary URL
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['url'] != null) {
          final cloudinaryUrl = responseData['url'] as String;

          // Update the user profile with the new image URL
          await updateProfileImage(cloudinaryUrl);

          return cloudinaryUrl;
        }
      }

      throw ApiException(
        'Failed to upload profile image',
        response.statusCode,
        response.body,
      );
    } catch (e) {
      log('Error uploading profile image to Cloudinary: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while uploading profile image',
        500,
        e.toString(),
      );
    }
  }

  /// Delete profile image from Cloudinary via the backend
  Future<bool> deleteProfileImageFromCloudinary() async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }

      final response = await _client.delete(
        Uri.parse('${CloudinaryConstants.deleteEndpoint}'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }

      throw ApiException(
        'Failed to delete profile image',
        response.statusCode,
        response.body,
      );
    } catch (e) {
      log('Error deleting profile image from Cloudinary: $e');
      return false;
    }
  }

  Future<void> updateUsername(String username) async {
    try {
      final tokens = await _authService.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }

      // Log the request for debugging
      log('Sending username update request to: $_baseUrl/user/profile');

      final response = await _client.patch(
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
        }),
      );

      // Log the response status for debugging
      log('Username update response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update username',
          response.statusCode,
          response.body,
        );
      }

      // Update the cached profile with the new username
      final cachedProfile = await getCachedProfile();
      if (cachedProfile != null) {
        final updatedProfile = cachedProfile.copyWith(username: username);
        await _cacheProfile(updatedProfile);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while updating username',
        500,
        e.toString(),
      );
    }
  }
}