import 'package:flutter/material.dart';
import '../../data/models/tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  User? _user;
  Tokens? _tokens;

  User? get user => _user;
  Tokens? get tokens => _tokens;

  String? _userId;
  String? get userId => _userId;

  Future<void> signIn(String email, String password) async {
    try {
      AuthResponse authResponse = await _authRepository.signIn(email, password);
      _userId = authResponse.userId;
      _tokens = authResponse.tokens;
      _user = await _authRepository.getUser();
      notifyListeners();
    } on Exception catch (e) {
      if (e.toString().contains('User not found')) {
        throw Exception('User not found');
      } else if (e.toString().contains('Incorrect password')) {
        throw Exception('Incorrect password');
      } else {
        throw Exception(e.toString());
      }
    }
  }

  Future<void> signUp(String username ,String email, String password) async {
    AuthResponse authResponse = await _authRepository.signUp(username ,email, password);
    _tokens = authResponse.tokens;
    _user = await _authRepository.getUser();
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    await _authRepository.saveUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _tokens = await _authRepository.getTokens();
    _user = await _authRepository.getUser();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _tokens = null;
    _user = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.forgotPassword(email);
      // Optionally, you can notify listeners or handle UI changes here
    } on Exception catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  Future<void> resetPassword(
    String email,
    String newPassword,
  ) async {
    try {
      await _authRepository.resetPassword(email, newPassword);
    } on Exception catch (e) {
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    try {
      await _authRepository.verifyOtp(email, otp);
      // Optionally, you can notify listeners or handle UI changes here
    } on Exception catch (e) {
      throw Exception('Failed to verify OTP: ${e.toString()}');
    }
  }
}
