import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Local data source for profile-related local storage
class ProfileLocalDataSource {
  final SharedPreferences _prefs;
  final Logger _logger = Logger('ProfileLocalDataSource');
  static const String _profileCacheKey = 'cached_user_profile';

  ProfileLocalDataSource({required SharedPreferences prefs}) : _prefs = prefs;

  /// Save user profile to local storage
  Future<void> cacheProfile(User profile) async {
    try {
      _logger.info('Caching user profile: ${profile.username}');
      await _prefs.setString(_profileCacheKey, jsonEncode(profile.toJson()));
    } catch (e) {
      _logger.severe('Error caching profile: $e');
      rethrow;
    }
  }

  /// Get user profile from local storage
  Future<User?> getCachedProfile() async {
    try {
      final String? profileJson = _prefs.getString(_profileCacheKey);
      if (profileJson == null) {
        _logger.info('No cached profile found in local storage');
        return null;
      }
      
      _logger.info('Cached profile found in local storage');
      return User.fromJson(jsonDecode(profileJson));
    } catch (e) {
      _logger.severe('Error getting cached profile: $e');
      return null;
    }
  }

  /// Clear cached profile from local storage
  Future<void> clearCachedProfile() async {
    try {
      _logger.info('Clearing cached profile from local storage');
      await _prefs.remove(_profileCacheKey);
    } catch (e) {
      _logger.severe('Error clearing cached profile: $e');
      rethrow;
    }
  }
} 