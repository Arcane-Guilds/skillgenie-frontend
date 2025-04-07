import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/lab_model.dart';
import '../../data/repositories/lab_repository.dart';

class LabViewModel extends ChangeNotifier {
  final LabRepository _labRepository;
  
  Lab? _currentLab;
  bool _isLoading = false;
  String? _errorMessage;
  List<Hint>? _currentHints;
  LabSubmission? _currentSubmission;
  String _currentCode = '';
  String _selectedLanguage = 'javascript';

  LabViewModel({required LabRepository labRepository}) 
      : _labRepository = labRepository;

  // Getters
  Lab? get currentLab => _currentLab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Hint>? get currentHints => _currentHints;
  LabSubmission? get currentSubmission => _currentSubmission;
  String get currentCode => _currentCode;
  String get selectedLanguage => _selectedLanguage;
  
  // Check if user is authenticated before making API calls
  Future<bool> _checkAuthentication(BuildContext? context) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    
    if (accessToken == null || accessToken.isEmpty) {
      _setError('You need to be logged in to access lab features');
      
      // If context is provided, navigate to login screen
      if (context != null) {
        GoRouter.of(context).go('/login');
      }
      
      return false;
    }
    
    return true;
  }
  
  // Actions
  Future<void> fetchLabByChapter(String chapterId, {BuildContext? context}) async {
    try {
      _setLoading(true);
      clearError();
      
      // Check auth before making API call
      if (!(await _checkAuthentication(context))) {
        _setLoading(false);
        return;
      }
      
      final lab = await _labRepository.getLabByChapter(chapterId);
      _currentLab = lab;
      
      // Set the starter code for the selected language
      if (lab.supportedLanguages.isNotEmpty) {
        if (!lab.supportedLanguages.contains(_selectedLanguage)) {
          _selectedLanguage = lab.supportedLanguages.first;
        }
        _currentCode = lab.starterCode.code;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load lab: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateLabsForCourse(String courseId, {BuildContext? context}) async {
    try {
      _setLoading(true);
      clearError();
      
      // Check auth before making API call
      if (!(await _checkAuthentication(context))) {
        _setLoading(false);
        return;
      }
      
      await _labRepository.generateLabsForCourse(courseId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to generate labs: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitCode(String userId, {BuildContext? context}) async {
    if (_currentLab == null) {
      _setError('No lab loaded');
      return;
    }

    try {
      _setLoading(true);
      clearError();
      
      // Check auth before making API call
      if (!(await _checkAuthentication(context))) {
        _setLoading(false);
        return;
      }
      
      final request = LabSubmitRequest(
        userId: userId,
        labId: _currentLab!.id,
        code: _currentCode,
        language: _selectedLanguage,
      );
      
      // Log the request data for debugging
      print('Submitting code for lab: ${_currentLab!.id}');
      print('User ID: $userId');
      print('Language: $_selectedLanguage');
      print('Code length: ${_currentCode.length} characters');
      
      final response = await _labRepository.submitCode(request);
      
      // Always set the submission regardless of success status
      // This ensures we always have test results to show
      if (response.submission != null) {
        _currentSubmission = response.submission;
      }
      
      // Check if submission was successful
      if (!response.success) {
        // Handle error response based on error type
        final errorMsg = response.error ?? 'An error occurred during code submission';
        print('Submission failed: $errorMsg');
        
        // Check for specific error types to provide better messages
        if (errorMsg.contains('docker_engine') || 
            errorMsg.contains('Docker') || 
            errorMsg.contains('ENOENT') ||
            errorMsg.contains('Code execution failed')) {
          _setError('Docker environment error: The code execution service is currently unavailable');
        } else {
          _setError(errorMsg);
        }
      }
      
      notifyListeners();
    } catch (e) {
      final errorMsg = e.toString();
      print('Exception during code submission: $errorMsg');
      
      if (errorMsg.contains('docker') || errorMsg.contains('ENOENT')) {
        _setError('Server error: Code execution environment is unavailable');
      } else {
        _setError('Failed to submit code. Please check your solution and try again.');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchHints(String userId, {BuildContext? context}) async {
    if (_currentLab == null) {
      _setError('No lab loaded');
      return;
    }

    try {
      _setLoading(true);
      clearError();
      
      // Check auth before making API call
      if (!(await _checkAuthentication(context))) {
        _setLoading(false);
        return;
      }
      
      final hints = await _labRepository.getHints(_currentLab!.id, userId);
      _currentHints = hints;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch hints: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> purchaseHint(String userId, int hintIndex, {BuildContext? context}) async {
    if (_currentLab == null) {
      _setError('No lab loaded');
      return;
    }

    try {
      _setLoading(true);
      clearError();
      
      // Check auth before making API call
      if (!(await _checkAuthentication(context))) {
        _setLoading(false);
        return;
      }
      
      await _labRepository.purchaseHint(_currentLab!.id, userId, hintIndex);
      
      // Refresh hints after purchase
      await fetchHints(userId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to purchase hint: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Code editing
  void updateCode(String newCode) {
    _currentCode = newCode;
    notifyListeners();
  }

  void setSelectedLanguage(String language) {
    if (_currentLab != null && _currentLab!.supportedLanguages.contains(language)) {
      _selectedLanguage = language;
      notifyListeners();
    }
  }

  void resetSubmission() {
    _currentSubmission = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 