import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../models/course_model.dart';

class CourseRepository {
  final Logger _logger = Logger();
  final http.Client _client;

  CourseRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Generate a course based on quiz results
  Future<Course> generateCourse(String id) async {
    try {
      _logger.i('Generating course for quiz result: $id');
      
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/course/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': id}),
      );

      if (response.statusCode == 201) {
        final courseData = jsonDecode(response.body);
        return Course.fromJson(courseData);
      } else {
        _logger.e('Failed to generate course: ${response.body}');
        throw Exception('Failed to generate course: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error generating course: $e');
      throw Exception('Error generating course: $e');
    }
  }

  /// Get all courses for a user
  Future<List<Course>> getUserCourses(String userId) async {
    try {
      _logger.i('Fetching courses for user: $userId');
      
      // Try to get courses by user ID
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/course/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> coursesData = jsonDecode(response.body);
        if (coursesData.isEmpty) {
          _logger.w('No courses found for user: $userId');
        }
        return coursesData.map((data) => Course.fromJson(data)).toList();
      } else {
        _logger.e('Failed to fetch user courses: ${response.body}');
        throw Exception('Failed to fetch user courses: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching user courses: $e');
      throw Exception('Error fetching user courses: $e');
    }
  }

  /// Get a course by ID
  Future<Course> getCourseById(String courseId) async {
    try {
      _logger.i('Fetching course by ID: $courseId');
      
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/course/$courseId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final courseData = jsonDecode(response.body);
        return Course.fromJson(courseData);
      } else {
        _logger.e('Failed to fetch course: ${response.body}');
        throw Exception('Failed to fetch course: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching course: $e');
      throw Exception('Error fetching course: $e');
    }
  }

  /// Update course progress
  Future<Course> updateCourseProgress(String courseId, String progressKey, int value) async {
    try {
      _logger.i('Updating course progress: $courseId, $progressKey=$value');
      
      final response = await _client.patch(
        Uri.parse('${ApiConstants.baseUrl}/course/$courseId/progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'progressKey': progressKey,
          'value': value,
        }),
      );

      if (response.statusCode == 200) {
        final courseData = jsonDecode(response.body);
        return Course.fromJson(courseData);
      } else {
        _logger.e('Failed to update course progress: ${response.body}');
        throw Exception('Failed to update course progress: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error updating course progress: $e');
      throw Exception('Error updating course progress: $e');
    }
  }

  /// Update current level
  Future<Course> updateCurrentLevel(String courseId, int level) async {
    try {
      _logger.i('Updating current level: $courseId, level=$level');
      
      final response = await _client.patch(
        Uri.parse('${ApiConstants.baseUrl}/course/$courseId/level'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'level': level,
        }),
      );

      if (response.statusCode == 200) {
        final courseData = jsonDecode(response.body);
        return Course.fromJson(courseData);
      } else {
        _logger.e('Failed to update current level: ${response.body}');
        throw Exception('Failed to update current level: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error updating current level: $e');
      throw Exception('Error updating current level: $e');
    }
  }

  /// Submit a code solution for verification
  Future<Map<String, dynamic>> submitCodeSolution(String courseId, String progressKey, String code) async {
    try {
      _logger.i('Submitting code solution for $courseId, $progressKey');
      
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/course/$courseId/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'progressKey': progressKey,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['success'] ?? false,
          'message': result['message'] ?? 'Code verification completed',
          'course': result['course'] != null ? Course.fromJson(result['course']) : null,
        };
      } else {
        _logger.e('Failed to verify code: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to verify code: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Error verifying code: $e');
      return {
        'success': false,
        'message': 'Error verifying code: $e',
      };
    }
  }

  /// Submit a quiz answer for verification
  Future<Map<String, dynamic>> submitQuizAnswer(String courseId, String progressKey, String answer) async {
    try {
      _logger.i('Submitting quiz answer for $courseId, $progressKey');
      
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/course/$courseId/verify-quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'progressKey': progressKey,
          'answer': answer,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['success'] ?? false,
          'message': result['message'] ?? 'Quiz verification completed',
          'course': result['course'] != null ? Course.fromJson(result['course']) : null,
        };
      } else {
        _logger.e('Failed to verify quiz answer: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to verify quiz answer: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Error verifying quiz answer: $e');
      return {
        'success': false,
        'message': 'Error verifying quiz answer: $e',
      };
    }
  }

  /// Submit a challenge solution
  Future<Map<String, dynamic>> submitChallengeSolution(String courseId, String levelKey, String chapterKey, String code) async {
    try {
      _logger.i('Submitting challenge solution for $courseId, L$levelKey-C$chapterKey');
      
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/course/$courseId/challenge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'levelKey': levelKey,
          'chapterKey': chapterKey,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['success'] ?? false,
          'message': result['message'] ?? 'Challenge verification completed',
          'testResults': result['testResults'] ?? [],
          'course': result['course'] != null ? Course.fromJson(result['course']) : null,
        };
      } else {
        _logger.e('Failed to verify challenge solution: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to verify challenge solution: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Error verifying challenge solution: $e');
      return {
        'success': false,
        'message': 'Error verifying challenge solution: $e',
      };
    }
  }
}