import 'dart:async';
import 'package:logging/logging.dart';
import '../../core/constants/profile_constants.dart';
import '../models/user_model.dart';
import '../models/api_exception.dart';
import '../models/community/post.dart';
import 'api_client.dart';

/// Remote data source for profile-related API calls
class ProfileRemoteDataSource {
  final ApiClient _apiClient;
  final Logger _logger = Logger('ProfileRemoteDataSource');

  ProfileRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch user profile from the API
  Future<User> fetchUserProfile(String accessToken) async {
    try {
      _logger.info('Fetching user profile');
      
      // Add the token to the API client
      _apiClient.addAuthenticationToken(accessToken);
      
      final response = await _apiClient.getData(ProfileConstants.profile);
      final statusCode = response.statusCode ?? 500;
      
      _logger.info('Profile fetch response status: $statusCode');
      
      if (statusCode == 200) {
        final data = response.data;
        // Ensure the id field is set correctly
        data['id'] = data['_id'] ?? data['id'];
        return User.fromJson(data);
      } else if (statusCode == 401) {
        // Handle unauthorized specifically with a clear message
        throw ApiException(
          'Your session has expired. Please log in again.',
          401,
          'Unauthorized access',
        );
      } else {
        throw ApiException(
          'Failed to fetch profile',
          statusCode,
          response.data.toString(),
        );
      }
    } catch (e) {
      _logger.severe('Error fetching profile: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while fetching profile',
        500,
        e.toString(),
      );
    } finally {
      // Clean up by removing the token
      _apiClient.removeAuthenticationToken();
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String accessToken, Map<String, dynamic> profileData) async {
    try {
      _logger.info('Updating user profile with data: $profileData');
      
      // Add the token to the API client
      _apiClient.addAuthenticationToken(accessToken);
      
      final response = await _apiClient.patchRequest(ProfileConstants.profile, profileData);
      final statusCode = response.statusCode ?? 500;
      
      _logger.info('Profile update response status: $statusCode');
      
      if (statusCode == 401) {
        throw ApiException(
          'Your session has expired. Please log in again.',
          401,
          'Unauthorized access',
        );
      } else if (statusCode == 400) {
        throw ApiException(
          'Invalid profile data. Please check your input and try again.',
          400,
          response.data.toString(),
        );
      } else if (statusCode != 200) {
        throw ApiException(
          'Failed to update profile',
          statusCode,
          response.data.toString(),
        );
      }
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while updating profile',
        500,
        e.toString(),
      );
    } finally {
      // Clean up by removing the token
      _apiClient.removeAuthenticationToken();
    }
  }

  /// Update user bio
  Future<void> updateBio(String accessToken, String bio) async {
    try {
      _logger.info('Updating user bio');
      await updateUserProfile(accessToken, {'bio': bio});
    } catch (e) {
      _logger.severe('Error updating bio: $e');
      rethrow;
    }
  }

  /// Update username
  Future<void> updateUsername(String accessToken, String username) async {
    try {
      _logger.info('Updating username');
      await updateUserProfile(accessToken, {'username': username});
    } catch (e) {
      _logger.severe('Error updating username: $e');
      rethrow;
    }
  }

  /// Update profile image URL
  Future<void> updateProfileImage(String accessToken, String imageUrl) async {
    try {
      _logger.info('Updating profile image URL');
      await updateUserProfile(accessToken, {'avatar': imageUrl});
    } catch (e) {
      _logger.severe('Error updating profile image: $e');
      rethrow;
    }
  }

  /// Update password
  Future<void> updatePassword(String accessToken, String currentPassword, String newPassword) async {
    try {
      _logger.info('Updating password');
      // Add the token to the API client
      _apiClient.addAuthenticationToken(accessToken);
      
      final response = await _apiClient.putRequest(ProfileConstants.changePassword, {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      final statusCode = response.statusCode ?? 500;
      
      _logger.info('Password update response status: $statusCode');
      
      if (statusCode == 401) {
        throw ApiException(
          'Your session has expired. Please log in again.',
          401,
          'Unauthorized access',
        );
      } else if (statusCode != 200) {
        throw ApiException(
          'Failed to update password',
          statusCode,
          response.data.toString(),
        );
      }
    } catch (e) {
      _logger.severe('Error updating password: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while updating password',
        500,
        e.toString(),
      );
    } finally {
      // Clean up by removing the token
      _apiClient.removeAuthenticationToken();
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String accessToken) async {
    try {
      _logger.info('Deleting user account');
      
      // Add the token to the API client
      _apiClient.addAuthenticationToken(accessToken);
      
      final response = await _apiClient.deleteRequest('/user/profile');
      final statusCode = response.statusCode ?? 500;
      
      _logger.info('Account deletion response status: $statusCode');
      
      if (statusCode == 401) {
        throw ApiException(
          'Your session has expired. Please log in again.',
          401,
          'Unauthorized access',
        );
      } else if (statusCode != 200) {
        throw ApiException(
          'Failed to delete account',
          statusCode,
          response.data.toString(),
        );
      }
    } catch (e) {
      _logger.severe('Error deleting account: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Network error while deleting account',
        500,
        e.toString(),
      );
    } finally {
      // Clean up by removing the token
      _apiClient.removeAuthenticationToken();
    }
  }
}