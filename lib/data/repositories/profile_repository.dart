import 'dart:io';
import '../../core/services/profile_service.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../models/api_exception.dart';

/// Repository that handles all profile-related data operations
/// Acts as a single source of truth for profile data
class ProfileRepository {
  final ProfileService _profileService;
  final StorageService _storageService;

  ProfileRepository({
    required ProfileService profileService,
    required StorageService storageService,
  })  : _profileService = profileService,
        _storageService = storageService;

  /// Get the user profile from the API or cache
  Future<User> getUserProfile({bool forceRefresh = false}) async {
    try {
      // If we're forcing a refresh, we'll always go to the API
      if (forceRefresh) {
        return await _profileService.fetchUserProfile();
      }

      // Try to get cached profile first
      final cachedProfile = await _profileService.getCachedProfile();
      if (cachedProfile != null) {
        return cachedProfile;
      }

      // If no cached profile, fetch from API
      return await _profileService.fetchUserProfile();
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Update the user profile
  Future<void> updateUserProfile(User profile) async {
    try {
      await _profileService.updateUserProfile(profile);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Update the user's bio
  Future<void> updateBio(String bio) async {
    try {
      await _profileService.updateBio(bio);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Update the user's profile image
  Future<String?> uploadProfileImage(File image) async {
    try {
      return await _storageService.uploadProfileImage(image);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Update the user's password
  /// Returns true if password was successfully updated
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      // Validate password requirements
      _validatePasswordRequirements(newPassword);

      // Call the service to update the password
      await _profileService.updatePassword(currentPassword, newPassword);

      // Clear the profile cache after password change
      await _profileService.clearCache();

      return true;
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Delete the user profile
  Future<void> deleteUserProfile() async {
    try {
      await _profileService.deleteUserProfile();
      await _profileService.clearCache();
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Clear the profile cache
  Future<void> clearCache() async {
    try {
      await _profileService.clearCache();
    } catch (e) {
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

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>=+-_]').hasMatch(password)) {
      throw ApiException(
        'Password must contain at least one special character',
        400,
        'Invalid password',
      );
    }
  }

  /// Standardized exception handling
  Exception _handleException(dynamic e) {
    if (e is ApiException) {
      return e;
    }

    if (e is SocketException) {
      return ApiException(
        'Network connection error. Please check your internet connection.',
        -1,
        e.toString(),
      );
    }

    return ApiException(
      'An unexpected error occurred',
      500,
      e.toString(),
    );
  }
}