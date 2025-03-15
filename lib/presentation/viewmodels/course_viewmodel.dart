import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

class CourseViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;

  List<Course> _userCourses = [];
  Course? _currentCourse;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGeneratingCourse = false;
  bool _isUpdatingProgress = false;

  // State variables for verification status
  bool _isVerifyingCode = false;
  bool _isVerifyingQuiz = false;
  bool _isVerifyingChallenge = false;
  String? _verificationMessage;
  List<TestResult>? _testResults;

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
  List<TestResult>? get testResults => _testResults;

  // Fetch all courses for a user
  Future<void> fetchUserCourses(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _safeNotifyListeners();

      _userCourses = await _courseRepository.getUserCourses(userId);
    } catch (e) {
      _errorMessage = 'Failed to fetch courses: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Safe method to call notifyListeners()
  void _safeNotifyListeners() {
    // Only notify if not disposed
    try {
      notifyListeners();
    } catch (e) {
      print('Error notifying listeners: $e');
    }
  }

  // Get a course by ID
  Future<void> fetchCourseById(String courseId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _safeNotifyListeners();

      _currentCourse = await _courseRepository.getCourseById(courseId);
    } catch (e) {
      _errorMessage = 'Failed to fetch course: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Generate a course based on user ID
  Future<Course?> generateCourse(String userId) async {
    try {
      _isGeneratingCourse = true;
      _errorMessage = null;
      _safeNotifyListeners();

      final course = await _courseRepository.generateCourse(userId);
      _currentCourse = course;
      
      // Add the new course to the user's courses list
      if (!_userCourses.any((c) => c.id == course.id)) {
        _userCourses.add(course);
      }
      
      return course;
    } catch (e) {
      _errorMessage = 'Failed to generate course: ${e.toString()}';
      return null;
    } finally {
      _isGeneratingCourse = false;
      _safeNotifyListeners();
    }
  }

  // Update course progress
  Future<void> updateCourseProgress(String courseId, String progressKey, int value) async {
    try {
      _isUpdatingProgress = true;
      _safeNotifyListeners();

      // Update progress in the repository
      final updatedCourse = await _courseRepository.updateCourseProgress(courseId, progressKey, value);
      
      // Update the current course
      _currentCourse = updatedCourse;
      
      // Update the course in the user's courses list
      final index = _userCourses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _userCourses[index] = updatedCourse;
      }
    } catch (e) {
      _errorMessage = 'Failed to update progress: ${e.toString()}';
    } finally {
      _isUpdatingProgress = false;
      _safeNotifyListeners();
    }
  }

  // Update current level
  Future<void> updateCurrentLevel(String courseId, int level) async {
    try {
      _isUpdatingProgress = true;
      _safeNotifyListeners();

      // Update current level in the repository
      final updatedCourse = await _courseRepository.updateCurrentLevel(courseId, level);
      
      // Update the current course
      _currentCourse = updatedCourse;
      
      // Update the course in the user's courses list
      final index = _userCourses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _userCourses[index] = updatedCourse;
      }
    } catch (e) {
      _errorMessage = 'Failed to update level: ${e.toString()}';
    } finally {
      _isUpdatingProgress = false;
      _safeNotifyListeners();
    }
  }

  // Clear current course
  void clearCurrentCourse() {
    _currentCourse = null;
    _safeNotifyListeners();
  }

  // Methods for submitting solutions
  Future<bool> submitCodeSolution(String courseId, String progressKey, String code) async {
    try {
      _isVerifyingCode = true;
      _verificationMessage = null;
      _safeNotifyListeners();

      final response = await _courseRepository.submitCodeSolution(courseId, progressKey, code);
      _verificationMessage = response['message'];
      
      if (response['success']) {
        // Update course progress if needed
        await updateCourseProgress(courseId, progressKey, 1);
      }

      return response['success'];
    } catch (e) {
      _verificationMessage = 'Error verifying code: ${e.toString()}';
      return false;
    } finally {
      _isVerifyingCode = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> submitQuizAnswer(String courseId, String progressKey, String answer) async {
    try {
      _isVerifyingQuiz = true;
      _verificationMessage = null;
      _safeNotifyListeners();

      final response = await _courseRepository.submitQuizAnswer(courseId, progressKey, answer);
      _verificationMessage = response['message'];
      
      if (response['success']) {
        // Update course progress if needed
        await updateCourseProgress(courseId, progressKey, 1);
      }

      return response['success'];
    } catch (e) {
      _verificationMessage = 'Error verifying quiz answer: ${e.toString()}';
      return false;
    } finally {
      _isVerifyingQuiz = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> submitChallengeSolution(String courseId, String levelKey, String chapterKey, String code) async {
    try {
      _isVerifyingChallenge = true;
      _verificationMessage = null;
      _testResults = null;
      _safeNotifyListeners();

      final response = await _courseRepository.submitChallengeSolution(courseId, levelKey, chapterKey, code);
      _verificationMessage = response['message'];
      
      // Convert test results to TestResult objects
      if (response['testResults'] != null) {
        _testResults = (response['testResults'] as List)
            .map((result) => TestResult.fromJson(result))
            .toList();
      }
      
      if (response['success']) {
        // Update course progress if needed
        await updateCourseProgress(courseId, levelKey, 1);
      }

      return response['success'];
    } catch (e) {
      _verificationMessage = 'Error verifying challenge solution: ${e.toString()}';
      return false;
    } finally {
      _isVerifyingChallenge = false;
      _safeNotifyListeners();
    }
  }

  // Helper method to update course progress
  Future<void> _updateCourseProgress(Course? updatedCourse) async {
    if (updatedCourse != null) {
      // Update the local course data
      _currentCourse = updatedCourse;
      _safeNotifyListeners();
    }
  }
}

// Model class for test results
class TestResult {
  final String testCase;
  final bool passed;
  final String message;

  TestResult({
    required this.testCase,
    required this.passed,
    required this.message,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testCase: json['testCase'] as String? ?? 'Unknown test',
      passed: json['passed'] as bool? ?? false,
      message: json['message'] as String? ?? (json['passed'] == true ? 'Test passed' : 'Test failed'),
    );
  }
}