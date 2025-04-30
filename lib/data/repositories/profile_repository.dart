import 'dart:io';
import 'package:logging/logging.dart';
import '../datasources/profile_remote_datasource.dart';
import '../datasources/profile_local_datasource.dart';
import '../repositories/auth_repository.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../models/api_exception.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

/// Repository for profile-related operations
class ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;
  final AuthRepository _authRepository;
  final StorageService _storageService;
  final Logger _logger = Logger('ProfileRepository');

  ProfileRepository({
    required ProfileRemoteDataSource remoteDataSource,
    required ProfileLocalDataSource localDataSource,
    required AuthRepository authRepository,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _authRepository = authRepository,
        _storageService = storageService;

  /// Get the user profile from the API or cache
  Future<User> getUserProfile({bool forceRefresh = false}) async {
    try {
      _logger.info('Getting user profile, forceRefresh: $forceRefresh');
      
      // If not forcing a refresh, try to get from cache first
      if (!forceRefresh) {
        final cachedProfile = await _localDataSource.getCachedProfile();
        if (cachedProfile != null) {
          _logger.info('Returning cached profile for user: ${cachedProfile.username}');
          return cachedProfile;
        }
      }
      
      // Get tokens for API call
      final tokens = await _authRepository.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      
      // Fetch from API
      final profile = await _remoteDataSource.fetchUserProfile(tokens.accessToken);
      
      // Cache the profile
      await _localDataSource.cacheProfile(profile);
      
      return profile;
    } catch (e) {
      _logger.severe('Error getting user profile: $e');
      throw _handleException(e);
    }
  }

  /// Update the user profile
  Future<void> updateUserProfile(User profile) async {
    try {
      _logger.info('Updating user profile for: ${profile.username}');
      
      // Get tokens for API call
      final tokens = await _authRepository.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      
      // Update profile via API
      await _remoteDataSource.updateUserProfile(tokens.accessToken, profile.toJson());
      
      // Update cached profile
      await _localDataSource.cacheProfile(profile);
    } catch (e) {
      _logger.severe('Error updating user profile: $e');
      throw _handleException(e);
    }
  }

  /// Update user bio
  Future<void> updateBio(String bio) async {
    try {
      _logger.info('Updating user bio');
      
      // Get tokens for API call
      final tokens = await _authRepository.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      
      // Update bio via API
      await _remoteDataSource.updateBio(tokens.accessToken, bio);
      
      // Update cached profile
      final cachedProfile = await _localDataSource.getCachedProfile();
      if (cachedProfile != null) {
        final updatedProfile = cachedProfile.copyWith(bio: bio);
        await _localDataSource.cacheProfile(updatedProfile);
      }
    } catch (e) {
      _logger.severe('Error updating bio: $e');
      throw _handleException(e);
    }
  }

  /// Update username
  Future<void> updateUsername(String username) async {
    try {
      _logger.info('Updating username to: $username');
      
      // Get tokens for API call
      final tokens = await _authRepository.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      
      // Update username via API
      await _remoteDataSource.updateUsername(tokens.accessToken, username);
      
      // Update cached profile
      final cachedProfile = await _localDataSource.getCachedProfile();
      if (cachedProfile != null) {
        final updatedProfile = cachedProfile.copyWith(username: username);
        await _localDataSource.cacheProfile(updatedProfile);
      }
    } catch (e) {
      _logger.severe('Error updating username: $e');
      throw _handleException(e);
    }
  }

  /// Upload profile image and update profile
  Future<void> updateProfileImage(
    File imageFile, {
    Function(double)? onProgress,
  }) async {
    try {
      _logger.info('Uploading profile image');
      
      // Upload image to storage service
      final imageUrl = await _storageService.uploadProfileImage(
        imageFile,
        onProgress: onProgress,
      );
      
      if (imageUrl == null || imageUrl.isEmpty) {
        throw ApiException('Failed to upload image', 500, 'Empty URL returned');
      }
      
      // Get tokens for API call
      final tokens = await _authRepository.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      
      // Update profile with new image URL
      await _remoteDataSource.updateProfileImage(tokens.accessToken, imageUrl);
      
      // Update cached profile
      final cachedProfile = await _localDataSource.getCachedProfile();
      if (cachedProfile != null) {
        final updatedProfile = cachedProfile.copyWith(avatar: imageUrl);
        await _localDataSource.cacheProfile(updatedProfile);
      }
    } catch (e) {
      _logger.severe('Error updating profile image: $e');
      throw _handleException(e);
    }
  }

  /// Delete profile image
  Future<bool> deleteProfileImage() async {
    try {
      _logger.info('Deleting profile image');
      
      // Get the current profile to get the avatar URL
      final currentProfile = await _localDataSource.getCachedProfile();
      if (currentProfile == null || currentProfile.avatar?.isEmpty == true) {
        return true; // No image to delete
      }

      // Ensure we have a non-null avatar URL
      final avatarUrl = currentProfile.avatar;
      if (avatarUrl == null || avatarUrl.isEmpty) {
        return true; // No image to delete
      }
      
      // Delete image from storage service
      final success = await _storageService.deleteProfileImage(avatarUrl);
      
      if (success) {
        // Get tokens for API call
        final tokens = await _authRepository.getTokens();
        if (tokens == null) {
          throw ApiException('No authentication tokens found', 401, 'Unauthorized');
        }
        
        // Update profile to remove image URL
        await _remoteDataSource.updateProfileImage(tokens.accessToken, '');
        
        // Update cached profile
        final updatedProfile = currentProfile.copyWith(avatar: '');
        await _localDataSource.cacheProfile(updatedProfile);
      }
      
      return success;
    } catch (e) {
      _logger.severe('Error deleting profile image: $e');
      throw _handleException(e);
    }
  }

  /// Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      _logger.info('Updating password');
      
      // Validate password requirements
      _validatePasswordRequirements(newPassword);
      
      // Get tokens for API call
      final tokens = await _authRepository.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      
      // Update password via API
      await _remoteDataSource.updatePassword(
        tokens.accessToken,
        currentPassword,
        newPassword,
      );
      
      // Clear cached profile after password change
      await _localDataSource.clearCachedProfile();
    } catch (e) {
      _logger.severe('Error updating password: $e');
      throw _handleException(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      _logger.info('Deleting user account');
      
      // Get tokens for API call
      final tokens = await _authRepository.getTokens();
      if (tokens == null) {
        throw ApiException('No authentication tokens found', 401, 'Unauthorized');
      }
      
      // Delete account via API
      await _remoteDataSource.deleteAccount(tokens.accessToken);
      
      // Clear local data
      await _localDataSource.clearCachedProfile();
      await _authRepository.signOut();
    } catch (e) {
      _logger.severe('Error deleting account: $e');
      throw _handleException(e);
    }
  }

  /// Clear the profile cache
  Future<void> clearCache() async {
    try {
      _logger.info('Clearing profile cache');
      await _localDataSource.clearCachedProfile();
    } catch (e) {
      _logger.severe('Error clearing cache: $e');
      throw _handleException(e);
    }
  }

  /// Validate password requirements
  void _validatePasswordRequirements(String password) {
    if (password.length < 8) {
      throw ApiException(
        'Password must be at least 8 characters long',
        400,
        'Invalid password',
      );
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      throw ApiException(
        'Password must contain at least one uppercase letter',
        400,
        'Invalid password',
      );
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      throw ApiException(
        'Password must contain at least one lowercase letter',
        400,
        'Invalid password',
      );
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      throw ApiException(
        'Password must contain at least one number',
        400,
        'Invalid password',
      );
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>=+\-_]').hasMatch(password)) {
      throw ApiException(
        'Password must contain at least one special character',
        400,
        'Invalid password',
      );
    }
  }

  /// Handle exceptions and convert to appropriate error types
  ApiException _handleException(dynamic e) {
    if (e is ApiException) {
      return e;
    }
    
    if (e is SocketException) {
      return ApiException(
        'Network connection error. Please check your internet connection.',
        503,
        e.toString(),
      );
    }
    
    return ApiException(
      'An unexpected error occurred.',
      500,
      e.toString(),
    );
  }

  Future<int> fetchUserStreak(String userId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/users/$userId/streak'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['currentStreak'] as int;
    } else {
      throw Exception('Failed to load user streak');
    }
  }
}
