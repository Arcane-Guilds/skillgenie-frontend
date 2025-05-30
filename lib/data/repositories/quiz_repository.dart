import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:skillGenie/core/constants/quiz_constants.dart';
import '../models/quiz_question.dart';
import '../models/evaluation_question.dart';

/// Repository for quiz-related operations
class QuizRepository {
  final http.Client _client;
  final Logger _logger = Logger('QuizRepository');

  QuizRepository({required http.Client client}) : _client = client;

  /// Fetch quiz questions from the API
  Future<List<QuizQuestion>> fetchQuizQuestions() async {
    try {
      _logger.info('Fetching quiz questions');
      final response = await _client.get(Uri.parse(QuizConstants.fetchQuizQuestions));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((question) => QuizQuestion.fromJson(question)).toList();
      } else {
        throw Exception('Failed to load quiz questions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error fetching quiz questions: $e');
      rethrow;
    }
  }

  /// Submit quiz answers to the API
Future<String> submitQuiz(String userId, Map<int, dynamic> answers) async {
  try {
    _logger.info('Submitting quiz for user: $userId');
    final payload = {
      'userId': userId,
      'topic': answers[1] ?? '', // Q1
      'experienceLevel': answers[2] ?? '', // Q2
      'learningGoal': answers[3] ?? '', // Q3
      'subtopics': answers[4] is List<String> 
          ? answers[4] 
          : (answers[4] != null ? answers[4].toString().split(',').map((s) => s.trim()).toList() : []), // Q4
      'learningPreference': answers[5] ?? '', // Q5
      'motivation': answers[6] ?? '', // Q6
      'weeklyTime': answers[7] ?? '', // Q7
      'priorExperience': answers[8] ?? '', // Q8
      'projectType': answers[9] ?? '', // Q9
      'specificProblem': answers[10] ?? '', // Q10 (optional)
    };

    final response = await _client.post(
      Uri.parse(QuizConstants.submitQuiz),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return responseData['_id'];
    } else {
      throw Exception('Failed to submit quiz: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    _logger.severe('Error submitting quiz: $e');
    rethrow;
  }
}
  /// Generate evaluation test based on quiz results
  Future<List<EvaluationQuestion>> generateEvaluationTest(String quizResultId) async {
    try {
      _logger.info('Generating evaluation test for quiz result: $quizResultId');
      final response = await _client.post(
        Uri.parse(QuizConstants.generateEvaluationTest),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quizResultId': quizResultId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EvaluationQuestion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to generate evaluation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error generating evaluation test: $e');
      rethrow;
    }
  }

  /// Submit evaluation answers to the API
  Future<double> submitEvaluation(String testId, String userId, List<String> answers) async {
    try {
      _logger.info('Submitting evaluation for user: $userId, test: $testId');
      final response = await _client.post(
        Uri.parse(QuizConstants.submitEvaluation),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'testId': testId,
          'userId': userId,
          'answers': answers,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['score']?.toDouble() ?? 0.0;
      } else {
        throw Exception('Failed to submit evaluation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error submitting evaluation: $e');
      rethrow;
    }
  }
} 