import 'dart:convert';
import 'package:logging/logging.dart';
import '../../core/constants/auth_constants.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'api_client.dart';

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
    
    _logger.info('Sign-up Response Status Code: ${response.statusCode}');
    _logger.info('Sign-up Response Data: ${response.data}');

    // Check for successful response first
    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        return AuthResponse.fromJson(response.data);
      } else {
        _logger.severe('Sign up successful but API returned non-Map data: ${response.data}');
        throw Exception('Sign-up succeeded but failed to parse server response.');
      }
    }

    // Handle error responses
    String errorMessage = 'Sign-up failed. An unknown error occurred.';
    
    // Check if the error response body contains a specific message
    if (response.data is Map<String, dynamic> && response.data['message'] != null) {
        final serverMessage = response.data['message'].toString();
        _logger.warning('Sign up failed with server message: $serverMessage');
        // Use the server message directly if it's informative
        if (serverMessage.toLowerCase().contains('email already exists') || serverMessage.toLowerCase().contains('email_1 dup key')) {
            errorMessage = 'Email already exists. Please try logging in or use a different email.';
        } else if (serverMessage.toLowerCase().contains('username already exists')) {
            errorMessage = 'Username already taken. Please choose a different username.';
        } else {
            // Use the server message if it's not one of the known specific cases
            errorMessage = serverMessage;
        }
    } else if (response.data != null) {
        // If data is not a Map but exists, use its string representation
        _logger.warning('Sign up failed with non-Map data: ${response.data}');
        errorMessage = 'Sign-up failed: ${response.data.toString()}';
    }
    
    // Fallback check based on status code if no specific message was extracted
    if (errorMessage == 'Sign-up failed. An unknown error occurred.') { 
        if (response.statusCode == 409) { 
            errorMessage = 'Email or username already exists.'; // More generic conflict message
        } else if (response.statusCode == 400) { 
            errorMessage = 'Invalid data provided. Please check your input.';
        } else if (response.statusCode! >= 500) {
             errorMessage = 'Server error during sign-up. Please try again later.';
        }
    }

    throw Exception(errorMessage);
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