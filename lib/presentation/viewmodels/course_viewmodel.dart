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

  CourseViewModel({required CourseRepository courseRepository})
      : _courseRepository = courseRepository;

  // Getters
  List<Course> get userCourses => _userCourses;
  Course? get currentCourse => _currentCourse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isGeneratingCourse => _isGeneratingCourse;
  bool get isUpdatingProgress => _isUpdatingProgress;

  // Fetch all courses for a user
  Future<void> fetchUserCourses(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _userCourses = await _courseRepository.getUserCourses(userId);
    } catch (e) {
      _errorMessage = 'Failed to fetch courses: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a course by ID
  Future<void> fetchCourseById(String courseId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentCourse = await _courseRepository.getCourseById(courseId);
    } catch (e) {
      _errorMessage = 'Failed to fetch course: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate a course based on user ID
  Future<Course?> generateCourse(String userId) async {
    try {
      _isGeneratingCourse = true;
      _errorMessage = null;
      notifyListeners();

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
      notifyListeners();
    }
  }

  // Update course progress
  Future<void> updateCourseProgress(String courseId, String progressKey, int value) async {
    try {
      _isUpdatingProgress = true;
      notifyListeners();

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
      notifyListeners();
    }
  }

  // Update current level
  Future<void> updateCurrentLevel(String courseId, int level) async {
    try {
      _isUpdatingProgress = true;
      notifyListeners();

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
      notifyListeners();
    }
  }

  // Clear current course
  void clearCurrentCourse() {
    _currentCourse = null;
    notifyListeners();
  }
}