import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../models/lab_model.dart';

class LabRepository {
  final _logger = Logger('LabRepository');
  final http.Client _client;

  LabRepository({http.Client? client}) : _client = client ?? http.Client();

  // Helper method to get authentication headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('accessToken');
    
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  /// Get a lab by chapter ID
  Future<Lab> getLabByChapter(String chapterId) async {
    try {
      _logger.info('Fetching lab for chapter: $chapterId');
      
      final headers = await _getAuthHeaders();
      _logger.info('Using headers: $headers');

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/lab/chapter/$chapterId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final labData = jsonDecode(response.body);
        return Lab.fromJson(labData);
      } else {
        _logger.severe('Failed to fetch lab: ${response.body}');
        throw Exception('Failed to fetch lab: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching lab: $e');
      throw Exception('Error fetching lab: $e');
    }
  }

  /// Submit code for a lab
  Future<LabResponse> submitCode(LabSubmitRequest request) async {
    try {
      _logger.info('Submitting code for lab: ${request.labId}');

      final headers = await _getAuthHeaders();
      _logger.info('Using headers: $headers');

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/lab/submit'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      _logger.info('Submit response status: ${response.statusCode}');
      _logger.info('Submit response body: ${response.body}');

      // Parse the response regardless of status code
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        // If body isn't valid JSON, create a basic error response
        responseData = {
          'error': 'Invalid server response: ${response.statusCode}',
          'message': response.body,
        };
      }

      // Handle Docker-specific errors
      if (response.body.contains('docker_engine') || 
          response.body.contains('ENOENT') ||
          (responseData.containsKey('message') && 
           responseData['message'].toString().contains('Code execution failed'))) {
        _logger.severe('Docker environment error: ${response.body}');
        return LabResponse(
          submission: LabSubmission(
            id: '',
            userId: request.userId,
            labId: request.labId,
            code: request.code,
            attempts: 0,
            purchasedHints: [],
            coinsSpent: 0,
            isComplete: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          error: 'The code execution environment (Docker) is currently unavailable. Your code was not executed.',
          success: false,
        );
      }

      // If status code isn't 200/201, add it to the error info
      if (response.statusCode != 200 && response.statusCode != 201) {
        responseData['error'] = 'Server returned ${response.statusCode}: ${responseData['error'] ?? responseData['message'] ?? 'Unknown error'}';
      }
      
      // Create LabResponse from the parsed data
      return LabResponse.fromJson(responseData);
    } catch (e) {
      _logger.severe('Error submitting code: $e');
      
      // Check if this is a Docker-related error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('docker') || errorStr.contains('enoent') || errorStr.contains('code execution')) {
        return LabResponse(
          submission: LabSubmission(
            id: '',
            userId: request.userId,
            labId: request.labId,
            code: request.code,
            attempts: 0,
            purchasedHints: [],
            coinsSpent: 0,
            isComplete: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          error: 'Docker environment error: The code execution service is currently unavailable',
          success: false,
        );
      }
      
      // Create a generic error response
      return LabResponse(
        submission: LabSubmission(
          id: '',
          userId: request.userId,
          labId: request.labId,
          code: request.code,
          attempts: 0,
          purchasedHints: [],
          coinsSpent: 0,
          isComplete: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        error: 'Error submitting code: $e',
        success: false,
      );
    }
  }

  /// Get hints for a lab
  Future<List<Hint>> getHints(String labId, String userId) async {
    try {
      _logger.info('Fetching hints for lab: $labId');

      final headers = await _getAuthHeaders();

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/lab/$labId/hints?userId=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final hintsData = jsonDecode(response.body) as List<dynamic>;
        return hintsData.map((hint) => Hint.fromJson(hint)).toList();
      } else {
        _logger.severe('Failed to fetch hints: ${response.body}');
        throw Exception('Failed to fetch hints: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching hints: $e');
      throw Exception('Error fetching hints: $e');
    }
  }

  /// Purchase a hint
  Future<void> purchaseHint(String labId, String userId, int hintIndex) async {
    try {
      _logger.info('Purchasing hint $hintIndex for lab: $labId');

      final headers = await _getAuthHeaders();

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/lab/$labId/hints/$hintIndex/purchase?userId=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _logger.severe('Failed to purchase hint: ${response.body}');
        throw Exception('Failed to purchase hint: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error purchasing hint: $e');
      throw Exception('Error purchasing hint: $e');
    }
  }

  /// Generate labs for a course
  Future<List<Lab>> generateLabsForCourse(String courseId) async {
    try {
      _logger.info('Generating labs for course: $courseId');

      final headers = await _getAuthHeaders();

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/lab/generate/$courseId'),
        headers: headers,
      );

      if (response.statusCode == 201) {
        final labsData = jsonDecode(response.body) as List<dynamic>;
        return labsData.map((lab) => Lab.fromJson(lab)).toList();
      } else {
        _logger.severe('Failed to generate labs: ${response.body}');
        throw Exception('Failed to generate labs: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error generating labs: $e');
      throw Exception('Error generating labs: $e');
    }
  }
}
