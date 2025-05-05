import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/auth_response.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/service_locator.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isSignedUp = false;
  bool get isSignedUp => _isSignedUp;
  bool isLoading = false;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _userId;
  String? get userId => _userId;

  // Use dependency injection through constructor
  SignUpViewModel({required AuthRepository authRepository}) 
      : _authRepository = authRepository;
  
  // Factory constructor that uses the service locator
  factory SignUpViewModel.fromServiceLocator() {
    return SignUpViewModel(
      authRepository: serviceLocator<AuthRepository>(),
    );
  }

  Future<void> signUp(BuildContext context, {required String username, required String email, required String password}) async {
  _setLoading(true);
  _errorMessage = null;
  notifyListeners();

  try {
    final AuthResponse response = await _authRepository.signUp(username, email, password);
    
    _isSignedUp = true;
    _userId = response.userId;
    _showSnackBar(context, "Sign-up successful!");

    // Navigate to the quiz screen after successful sign-up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(context).go('/quiz/$_userId');
    });
    } catch (e) {
    _showSnackBar(context, "Sign-up failed: $e");
    _errorMessage = e.toString();
  } finally {
    _setLoading(false);
  }
}

  Future<void> signUpWithFacebook() async {
    try {
      _setLoading(true);
      _errorMessage = null;
      notifyListeners();

      
      await Future.delayed(const Duration(seconds: 2)); // Simulate network call

      _isSignedUp = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}