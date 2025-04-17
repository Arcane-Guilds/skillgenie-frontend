import 'dart:convert';
import 'package:logging/logging.dart';
import '../../core/constants/auth_constants.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

/// Remote data source for authentication-related API calls
class AuthRemoteDataSource {
  final ApiClient _apiClient;
  final Logger _logger = Logger('AuthRemoteDataSource');

  AuthRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    _logger.info('Attempting to sign in with email: $email');
    final response = await _apiClient.postRequest(AuthConstants.signin, {
      "email": email,
      "password": password,
    });
    
    _logger.info('Response status code: ${response.statusCode}');
    
    if (response.statusCode == 401 && response.data['message'] == 'Incorrect password') {
      _logger.warning('Sign in failed: Incorrect password');
      throw Exception('Incorrect password');
    }

    return AuthResponse.fromJson(response.data);
  }

  /// Sign up with username, email, and password
  Future<AuthResponse> signUp(String username, String email, String password) async {
    _logger.info('Attempting to sign up with email: $email');
    final response = await _apiClient.postRequest(AuthConstants.signup, {
      "username": username,
      "email": email,
      "password": password,
    });
    
    _logger.info('Response status code: ${response.statusCode}');
    return AuthResponse.fromJson(response.data);
  }

  /// Send a password reset email
  Future<void> forgotPassword(String email) async {
    _logger.info('Sending forgot password request for email: $email');
    final response = await _apiClient.postRequest(AuthConstants.forgot_password, {"email": email});
    _logger.info('Forgot password response status: ${response.statusCode}');
  }

  /// Verify OTP for password reset
  Future<void> verifyOtp(String email, String otp) async {
    _logger.info('Verifying OTP for email: $email');
    final response = await _apiClient.postRequest(AuthConstants.verify_otp, {
      "email": email,
      "otp": otp,
    });
    _logger.info('OTP verification response status: ${response.statusCode}');
  }

  /// Reset password with email and new password
  Future<void> resetPassword(String email, String newPassword) async {
    _logger.info('Resetting password for email: $email');
    final response = await _apiClient.putRequest(AuthConstants.reset_password, {
      "email": email,
      "newPassword": newPassword,
    });
    _logger.info('Reset password response status: ${response.statusCode}');
  }

  /// Decode JWT token to extract user information
  User? decodeJwt(String token) {
    try {
      final parts = token.split(".");
      if (parts.length != 3) throw Exception("Invalid JWT format");

      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final jsonMap = jsonDecode(payload);

      return User.fromJson(jsonMap);
    } catch (e) {
      _logger.severe("Error decoding JWT: $e");
      return null;
    }
  }
} 