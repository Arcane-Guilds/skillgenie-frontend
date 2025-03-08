import 'package:flutter/material.dart';
import '../../../data/models/tokens.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/auth_response.dart';
import '../../../data/models/user_model.dart';

/// ViewModel for authentication-related operations
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  User? _user;
  Tokens? _tokens;
  String? _userId;
  String? _error;
  bool _isLoading = false;

  AuthViewModel({required AuthRepository authRepository}) 
      : _authRepository = authRepository;

  /// Get the current user
  User? get user => _user;
  
  /// Get the current tokens
  Tokens? get tokens => _tokens;
  
  /// Get the current user ID
  String? get userId => _userId;
  
  /// Get the current error message
  String? get error => _error;
  
  /// Check if the view model is loading
  bool get isLoading => _isLoading;

  /// Returns true if the user is authenticated (has valid tokens and user data)
  bool get isAuthenticated => _tokens != null && _user != null;

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      AuthResponse authResponse = await _authRepository.signIn(email, password);
      _userId = authResponse.userId;
      _tokens = authResponse.tokens;
      _user = await _authRepository.getUser();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('User not found')) {
        _error = 'User not found';
      } else if (e.toString().contains('Incorrect password')) {
        _error = 'Incorrect password';
      } else {
        _error = e.toString();
      }
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Sign up with username, email, and password
  Future<void> signUp(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      AuthResponse authResponse = await _authRepository.signUp(username, email, password);
      _tokens = authResponse.tokens;
      _user = await _authRepository.getUser();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Update the current user
  Future<void> setUser(User user) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authRepository.saveUser(user);
      _user = user;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Check if the user is authenticated
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _tokens = await _authRepository.getTokens();
      _user = await _authRepository.getUser();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authRepository.signOut();
      _tokens = null;
      _user = null;
      _userId = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to send password reset email: ${e.toString()}';
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Reset password with email and new password
  Future<void> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.resetPassword(email, newPassword);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to reset password: ${e.toString()}';
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Verify OTP for password reset
  Future<void> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.verifyOtp(email, otp);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to verify OTP: ${e.toString()}';
      notifyListeners();
      throw Exception(_error);
    }
  }
}