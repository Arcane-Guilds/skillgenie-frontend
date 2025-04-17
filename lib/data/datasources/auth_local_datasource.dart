import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tokens.dart';
import '../models/user_model.dart';

/// Local data source for authentication-related local storage
class AuthLocalDataSource {
  final SharedPreferences _prefs;
  final Logger _logger = Logger('AuthLocalDataSource');

  AuthLocalDataSource({required SharedPreferences prefs}) : _prefs = prefs;

  /// Save user to local storage
  Future<void> saveUser(User user) async {
    _logger.info('Saving user: ${user.username}');
    await _prefs.setString("user", jsonEncode(user.toJson()));
  }

  /// Get user from local storage
  Future<User?> getUser() async {
    final String? userJson = _prefs.getString("user");
    if (userJson == null) {
      _logger.info('No user found in local storage');
      return null;
    }
    
    _logger.info('User found in local storage');
    return User.fromJson(jsonDecode(userJson));
  }

  /// Save tokens to local storage
  Future<void> saveTokens(Tokens tokens) async {
    _logger.info('Saving tokens');
    await _prefs.setString("accessToken", tokens.accessToken);
    await _prefs.setString("refreshToken", tokens.refreshToken);
  }

  /// Get tokens from local storage
  Future<Tokens?> getTokens() async {
    final String? accessToken = _prefs.getString("accessToken");
    final String? refreshToken = _prefs.getString("refreshToken");

    if (accessToken == null || refreshToken == null) {
      _logger.info('No tokens found in local storage');
      return null;
    }
    
    _logger.info('Tokens found in local storage');
    return Tokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Clear all data from local storage
  Future<void> clearAll() async {
    _logger.info('Clearing all data from local storage');
    await _prefs.clear();
  }
} 