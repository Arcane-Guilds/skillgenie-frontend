import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/api_client.dart';
import '../models/auth_response.dart';
import '../models/tokens.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';
import 'package:logging/logging.dart';
class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  final Logger _logger = Logger('AuthRepository');

  Future<AuthResponse> signIn(String email, String password) async {
    _logger.info('Attempting to sign in with email: $email');
    final response = await _apiClient.postRequest(ApiConstants.signin, {
      "email": email,
      "password": password,
    });
    _logger.info('Response: $response');
    if (response.statusCode == 401 && response.data['message'] == 'Incorrect password') {
      _logger.warning('Sign in failed: Incorrect password');
      throw Exception('Incorrect password');
    }

    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse.tokens);
    User? user = _decodeJwt(authResponse.tokens.accessToken);
    if (user != null) await saveUser(user);
    return authResponse;
  }


  Future<AuthResponse> signUp(String username, String email, String password) async {
    final response = await _apiClient.postRequest(ApiConstants.signup, {
      "username": username,
      "email": email,
      "password": password,
    });

    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse.tokens);
    User? user = _decodeJwt(authResponse.tokens.accessToken);
    if (user != null) await saveUser(user);
    return authResponse;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    _logger.info('Saving user: ${jsonEncode(user.toJson())}');
    await prefs.setString("user", jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString("user");

    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  Future<void> _saveTokens(Tokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("accessToken", tokens.accessToken);
    await prefs.setString("refreshToken", tokens.refreshToken);
  }

  Future<void> saveTokens(Tokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("accessToken", tokens.accessToken);
    await prefs.setString("refreshToken", tokens.refreshToken);
  }

  Future<Tokens?> getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString("accessToken");
    final String? refreshToken = prefs.getString("refreshToken");

    if (accessToken == null || refreshToken == null) return null;
    return Tokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  User? _decodeJwt(String token) {
    try {
      final parts = token.split(".");
      if (parts.length != 3) throw Exception("Invalid JWT format");

      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final jsonMap = jsonDecode(payload);

      return User.fromJson(jsonMap);
    } catch (e) {
      print("Error decoding JWT: $e");
      return null;
    }
  }
  Future<void> forgotPassword(String email) async {
    _logger.info('Sending forgot password request for email: $email');
    final response = await _apiClient.postRequest(ApiConstants.forgot_password, {"email": email});
    _logger.info('Forgot password response: $response');
  }

  Future<void> verifyOtp(String email, String otp) async {
    _logger.info('Verifying OTP for email: $email');
    final response = await _apiClient.postRequest(ApiConstants.verify_otp, {
      "email": email,
      "otp": otp,
    });
    _logger.info('OTP verification response: $response');
  }


  Future<void> resetPassword(String email, String newPassword) async {
    _logger.info('Resetting password for email: $email');
    final response = await _apiClient.putRequest(ApiConstants.reset_password, {
      "email": email,
      "newPassword": newPassword,
    });
    _logger.info('Reset password response: $response');
  }
}
