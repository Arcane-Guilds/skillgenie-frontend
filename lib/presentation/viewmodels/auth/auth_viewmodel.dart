import 'package:flutter/material.dart';
import '../../../data/models/tokens.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/auth_response.dart';
import '../../../data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

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

  /// Get the current user (alias for user)
  User? get currentUser => _user;

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('Attempting to sign in with email: $email');
      AuthResponse authResponse = await _authRepository.signIn(email, password);
      _userId = authResponse.userId;
      _tokens = authResponse.tokens;
      
      // Verify we have received a valid token
      if (_tokens == null || _tokens!.accessToken.isEmpty) {
        throw Exception('Received invalid or empty token from server');
      }
      
      print('Login successful - userId: ${authResponse.userId}');
      print('Access token received (first 15 chars): ${_tokens!.accessToken.substring(0, math.min(15, _tokens!.accessToken.length))}...');
      
      // Save token in multiple places to ensure it's available
      // First, have the auth repository save it (normal flow)
      await _authRepository.saveTokens(_tokens!);
      
      // Second, use our SecureStorage directly for emergency backup
      final secureStorage = await _authRepository.getSecureStorage();
      final tokenSaved = await secureStorage.forceSetToken(_tokens!.accessToken);
      
      if (tokenSaved) {
        print('Token successfully force-saved to multiple storages');
      } else {
        print('WARNING: Force save of token may have failed!');
      }
      
      // Third, manually save to SharedPreferences as last resort
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _tokens!.accessToken);
      final savedToken = prefs.getString('accessToken');
      
      if (savedToken != null && savedToken.isNotEmpty) {
        print('Token also saved to direct SharedPreferences');
      } else {
        print('WARNING: Failed to save token to direct SharedPreferences!');
      }
      
      // Verify token is available via secure storage
      final hasToken = await secureStorage.hasAnyToken();
      if (!hasToken) {
        print('CRITICAL ERROR: Token verification failed! No token found in any storage after saving.');
      }
      
      _user = await _authRepository.getUser();
      
      if (_user != null) {
        print('User loaded successfully: ${_user!.username} (${_user!.id})');
        
        // Also save user ID
        await secureStorage.setUserId(_user!.id);
      } else {
        print('WARNING: User object is null after successful login');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error during sign in: $e');
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
    try {
      print('Checking authentication status...');
      _tokens = await _authRepository.getTokens();
      
      if (_tokens != null) {
        print('Tokens found - access token (first 15 chars): ${_tokens!.accessToken.substring(0, 15)}...');
        
        // Double check if token is also in secure storage
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('accessToken')) {
          print('Access token found in SharedPreferences');
        } else {
          print('WARNING: Token not found in SharedPreferences but is in repository');
        }
      } else {
        print('No tokens found, user is not authenticated');
      }
      
      _user = await _authRepository.getUser();
      
      if (_user != null) {
        print('User loaded: ${_user!.username} (${_user!.id})');
        print('Authentication status: User is authenticated');
      } else if (_tokens != null) {
        print('WARNING: Tokens found but user object is null');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error checking auth status: $e');
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