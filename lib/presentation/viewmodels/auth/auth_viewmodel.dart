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
  bool _authChecked = false; // Track if initial auth check is done
  bool _hasCompletedOnboarding = false; // Added for onboarding status

  // Key for SharedPreferences
  static const String _onboardingCompleteKey = 'hasCompletedOnboarding';

  AuthViewModel({required AuthRepository authRepository}) 
      : _authRepository = authRepository {
        // Optionally load status immediately, but checkAuthStatus might be better
        // _loadOnboardingStatus(); 
      }

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

  /// Returns true if the initial authentication check has been performed
  bool get authChecked => _authChecked;

  /// Returns true if the user has completed the onboarding process
  bool get hasCompletedOnboarding => _hasCompletedOnboarding; // Added getter

  /// Get the current user (alias for user)
  User? get currentUser => _user;

  /// Load onboarding status from SharedPreferences
  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedOnboarding = prefs.getBool(_onboardingCompleteKey) ?? false;
      print("Loaded onboarding status: $_hasCompletedOnboarding");
    } catch (e) {
      print("Error loading onboarding status: $e");
      _hasCompletedOnboarding = false; // Default to false on error
    }
    // No need to notifyListeners here unless UI depends directly on this load
  }

  /// Set onboarding status and save to SharedPreferences
  Future<void> setOnboardingComplete(bool complete) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_onboardingCompleteKey, complete);
      if (success) {
        _hasCompletedOnboarding = complete;
        print("Saved onboarding status: $_hasCompletedOnboarding");
        notifyListeners(); // Notify listeners as this state change might affect redirection
      } else {
         print("Error saving onboarding status to SharedPreferences.");
      }
    } catch (e) {
      print("Error saving onboarding status: $e");
    }
  }

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
      
      // Load onboarding status after successful login & user fetch
      await _loadOnboardingStatus(); 
      
      _isLoading = false;
      _authChecked = true; // Mark auth as checked after successful login
      notifyListeners();
    } catch (e) {
      print('Error during sign in: $e');
      _isLoading = false;
      // Set a generic user-friendly error message
      _error = 'Invalid email or password. Please try again.'; 
      _authChecked = true; // Mark as checked even on login failure
      notifyListeners();
      // Do NOT re-throw the exception here. The UI will listen for _error.
      // throw Exception(_error); 
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
      
      // Load onboarding status after signup
      await _loadOnboardingStatus(); 
      
      _authChecked = true; // Mark auth as checked
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _authChecked = true; // Mark as checked even on signup failure
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
    if (_authChecked) return; // Avoid redundant checks if already done

    _isLoading = true; // Indicate loading during the check
    notifyListeners(); // Notify start of check

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
      
      // Load onboarding status regardless of auth state
      await _loadOnboardingStatus(); 
      
      print('Authentication check complete.');
      
    } catch (e) {
      print('Error checking auth status: $e');
      _error = e.toString();
      // Ensure onboarding status is loaded even if auth check fails
      await _loadOnboardingStatus(); 
    } finally {
       _isLoading = false; // Stop loading indicator
       _authChecked = true; // Mark that the initial check has been performed
       notifyListeners(); // Notify completion of check
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
      
      _hasCompletedOnboarding = false; // Reset onboarding status on sign out
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey); // Remove from storage
      _authChecked = false; // Reset auth check status
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _hasCompletedOnboarding = false; 
      _authChecked = false; 
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

  /// Clears the current error message.
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}