import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../models/api_exception.dart';

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

  /// Upload and update the user's profile image
  /// Returns the Cloudinary URL of the uploaded image
  Future<String?> uploadProfileImage(File image, {Function(double)? onProgress}) async {
    try {
      // Method 1: Direct upload to Cloudinary from the client
      // This is faster but less secure
      final cloudinaryUrl = await _storageService.uploadProfileImage(
        image,
        onProgress: onProgress,
      );

      if (cloudinaryUrl != null) {
        // Update the user profile with the new image URL
        await _profileService.updateProfileImage(cloudinaryUrl);
        return cloudinaryUrl;
      }

      // If direct upload fails, try uploading via the backend
      return await _uploadViaBackend(image, onProgress: onProgress);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Upload profile image via the backend
  /// This is more secure but slightly slower
  Future<String?> _uploadViaBackend(File image, {Function(double)? onProgress}) async {
    try {
      // Create a multipart file from the image
      final fileExtension = path.extension(image.path).replaceAll('.', '');
      final mimeType = lookupMimeType(image.path) ?? 'image/$fileExtension';

      final multipartFile = http.MultipartFile(
        'file',
        image.openRead(),
        await image.length(),
        filename: path.basename(image.path),
        contentType: MediaType.parse(mimeType),
      );

      // Upload the image via the backend
      return await _profileService.uploadProfileImageToCloudinary(
        multipartFile,
        onProgress: onProgress,
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Delete the user's profile image
  Future<bool> deleteProfileImage() async {
    try {
      return await _profileService.deleteProfileImageFromCloudinary();
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

    if (!RegExp(r'[!@#\$%\^&\*\(\),.?":{}|<>=+\-_]').hasMatch(password)) {
      throw ApiException(
        'Password must contain at least one special character',
        400,
        'Invalid password',
      );
    }
  }

  /// Update the user's username
  Future<void> updateUsername(String username) async {
    try {
      // Validate username
      _validateUsername(username);

      // Call the service to update the username
      await _profileService.updateUsername(username);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Validate username requirements
  void _validateUsername(String username) {
    if (username.isEmpty) {
      throw ApiException(
        'Username cannot be empty',
        400,
        'Invalid username',
      );
    }

    if (username.length < 3) {
      throw ApiException(
        'Username must be at least 3 characters long',
        400,
        'Invalid username',
      );
    }

    if (username.length > 30) {
      throw ApiException(
        'Username must be less than 30 characters long',
        400,
        'Invalid username',
      );
    }

    // Only allow alphanumeric characters, underscores, and hyphens
    if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(username)) {
      throw ApiException(
        'Username can only contain letters, numbers, underscores, and hyphens',
        400,
        'Invalid username',
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
