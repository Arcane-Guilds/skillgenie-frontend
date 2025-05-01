import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

class CourseViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;

  final List<Course> _userCourses = [];
  Course? _currentCourse;
  final bool _isLoading = false;
  String? _errorMessage;
  final bool _isGeneratingCourse = false;
  final bool _isUpdatingProgress = false;
  bool _isVerifyingCode = false;
  bool _isVerifyingQuiz = false;
  bool _isVerifyingChallenge = false;
  String? _verificationMessage;
  bool? _verificationSuccess;
  List<Map<String, dynamic>>? _testResults;

  CourseViewModel({required CourseRepository courseRepository})
      : _courseRepository = courseRepository;

  // Getters
  List<Course> get userCourses => _userCourses;
  Course? get currentCourse => _currentCourse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isGeneratingCourse => _isGeneratingCourse;
  bool get isUpdatingProgress => _isUpdatingProgress;
  bool get isVerifyingCode => _isVerifyingCode;
  bool get isVerifyingQuiz => _isVerifyingQuiz;
  bool get isVerifyingChallenge => _isVerifyingChallenge;
  String? get verificationMessage => _verificationMessage;
  bool? get verificationSuccess => _verificationSuccess;
  List<Map<String, dynamic>>? get testResults => _testResults;

  // ... existing methods ...

  // Submit code solution for verification
  Future<bool> submitCodeSolution(String courseId, String progressKey, String code) async {
    try {
      _isVerifyingCode = true;
      _verificationMessage = null;
      _verificationSuccess = null;
      notifyListeners();

      final result = await _courseRepository.submitCodeSolution(courseId, progressKey, code);
      
      _verificationSuccess = result['success'] as bool;
      _verificationMessage = result['message'] as String;
      
      if (result['course'] != null) {
        _currentCourse = result['course'] as Course;
        
        // Update the course in the user's courses list
        final index = _userCourses.indexWhere((c) => c.id == courseId);
        if (index != -1) {
          _userCourses[index] = _currentCourse!;
        }
      }
      
      return _verificationSuccess!;
    } catch (e) {
      _errorMessage = 'Failed to verify code: ${e.toString()}';
      _verificationSuccess = false;
      _verificationMessage = _errorMessage;
      return false;
    } finally {
      _isVerifyingCode = false;
      notifyListeners();
    }
  }

  // Submit quiz answer for verification
  Future<bool> submitQuizAnswer(String courseId, String progressKey, String answer) async {
    try {
      _isVerifyingQuiz = true;
      _verificationMessage = null;
      _verificationSuccess = null;
      notifyListeners();

      final result = await _courseRepository.submitQuizAnswer(courseId, progressKey, answer);
      
      _verificationSuccess = result['success'] as bool;
      _verificationMessage = result['message'] as String;
      
      if (result['course'] != null) {
        _currentCourse = result['course'] as Course;
        
        // Update the course in the user's courses list
        final index = _userCourses.indexWhere((c) => c.id == courseId);
        if (index != -1) {
          _userCourses[index] = _currentCourse!;
        }
      }
      
      return _verificationSuccess!;
    } catch (e) {
      _errorMessage = 'Failed to verify quiz answer: ${e.toString()}';
      _verificationSuccess = false;
      _verificationMessage = _errorMessage;
      return false;
    } finally {
      _isVerifyingQuiz = false;
      notifyListeners();
    }
  }

  // Submit challenge solution
  Future<bool> submitChallengeSolution(String courseId, String levelKey, String chapterKey, String code) async {
    try {
      _isVerifyingChallenge = true;
      _verificationMessage = null;
      _verificationSuccess = null;
      _testResults = null;
      notifyListeners();

      final result = await _courseRepository.submitChallengeSolution(courseId, levelKey, chapterKey, code);
      
      _verificationSuccess = result['success'] as bool;
      _verificationMessage = result['message'] as String;
      _testResults = result['testResults'] as List<Map<String, dynamic>>?;
      
      if (result['course'] != null) {
        _currentCourse = result['course'] as Course;
        
        // Update the course in the user's courses list
        final index = _userCourses.indexWhere((c) => c.id == courseId);
        if (index != -1) {
          _userCourses[index] = _currentCourse!;
        }
      }
      
      return _verificationSuccess!;
    } catch (e) {
      _errorMessage = 'Failed to verify challenge solution: ${e.toString()}';
      _verificationSuccess = false;
      _verificationMessage = _errorMessage;
      return false;
    } finally {
      _isVerifyingChallenge = false;
      notifyListeners();
    }
  }

  // Reset verification state
  void resetVerificationState() {
    _verificationMessage = null;
    _verificationSuccess = null;
    _testResults = null;
    notifyListeners();
  }

  // Clear current course
  void clearCurrentCourse() {
    _currentCourse = null;
    notifyListeners();
  }
} 