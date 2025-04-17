import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/api_client.dart';
import '../models/auth_response.dart';
import '../models/tokens.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';
import 'package:logging/logging.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../core/storage/secure_storage.dart';
import 'package:get_it/get_it.dart';

/// Repository for authentication-related operations
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final Logger _logger = Logger('AuthRepository');

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Get the SecureStorage instance from the service locator
  Future<SecureStorage> getSecureStorage() async {
    try {
      // Try to get it from the service locator
      final GetIt serviceLocator = GetIt.instance;
      if (serviceLocator.isRegistered<SecureStorage>()) {
        _logger.info('Getting SecureStorage from service locator');
        return serviceLocator<SecureStorage>();
      }
      
      // If not registered, create a new instance
      _logger.warning('SecureStorage not registered, creating new instance');
      final prefs = await SharedPreferences.getInstance();
      return SecureStorage(prefs);
    } catch (e) {
      _logger.severe('Error getting SecureStorage: $e');
      // Fallback to creating a new instance
      final prefs = await SharedPreferences.getInstance();
      return SecureStorage(prefs);
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      _logger.info('Signing in with email: $email');
      final authResponse = await _remoteDataSource.signIn(email, password);
      
      // Save tokens to local storage
      await _localDataSource.saveTokens(authResponse.tokens);
      
      // Decode JWT and save user to local storage
      final user = _remoteDataSource.decodeJwt(authResponse.tokens.accessToken);
      if (user != null) {
        await _localDataSource.saveUser(user);
      }
      
      return authResponse;
    } catch (e) {
      _logger.severe('Error signing in: $e');
      rethrow;
    }
  }

  /// Sign up with username, email, and password
  Future<AuthResponse> signUp(String username, String email, String password) async {
    try {
      _logger.info('Signing up with email: $email');
      final authResponse = await _remoteDataSource.signUp(username, email, password);
      
      // Save tokens to local storage
      await _localDataSource.saveTokens(authResponse.tokens);
      
      // Decode JWT and save user to local storage
      final user = _remoteDataSource.decodeJwt(authResponse.tokens.accessToken);
      if (user != null) {
        await _localDataSource.saveUser(user);
      }
      
      return authResponse;
    } catch (e) {
      _logger.severe('Error signing up: $e');
      rethrow;
    }
  }

  /// Sign out by clearing local storage
  Future<void> signOut() async {
    try {
      _logger.info('Signing out');
      await _localDataSource.clearAll();
    } catch (e) {
      _logger.severe('Error signing out: $e');
      rethrow;
    }
  }

  /// Save user to local storage
  Future<void> saveUser(User user) async {
    try {
      _logger.info('Saving user: ${user.username}');
      await _localDataSource.saveUser(user);
    } catch (e) {
      _logger.severe('Error saving user: $e');
      rethrow;
    }
  }

  /// Get user from local storage
  Future<User?> getUser() async {
    try {
      _logger.info('Getting user from local storage');
      return await _localDataSource.getUser();
    } catch (e) {
      _logger.severe('Error getting user: $e');
      return null;
    }
  }


  /// Save tokens to local storage
  Future<void> saveTokens(Tokens tokens) async {
    try {
      _logger.info('Saving tokens');
      await _localDataSource.saveTokens(tokens);
    } catch (e) {
      _logger.severe('Error saving tokens: $e');
      rethrow;
    }
  }

  /// Get tokens from local storage
  Future<Tokens?> getTokens() async {
    try {
      _logger.info('Getting tokens from local storage');
      return await _localDataSource.getTokens();
    } catch (e) {
      _logger.severe('Error getting tokens: $e');
      return null;
    }
  }

  /// Send a password reset email
  Future<void> forgotPassword(String email) async {
    try {
      _logger.info('Sending forgot password request for email: $email');
      await _remoteDataSource.forgotPassword(email);
    } catch (e) {
      _logger.severe('Error sending forgot password request: $e');
      rethrow;
    }
  }

  /// Verify OTP for password reset
  Future<void> verifyOtp(String email, String otp) async {
    try {
      _logger.info('Verifying OTP for email: $email');
      await _remoteDataSource.verifyOtp(email, otp);
    } catch (e) {
      _logger.severe('Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Reset password with email and new password
  Future<void> resetPassword(String email, String newPassword) async {
    try {
      _logger.info('Resetting password for email: $email');
      await _remoteDataSource.resetPassword(email, newPassword);
    } catch (e) {
      _logger.severe('Error resetting password: $e');
      rethrow;
    }
  }
}
