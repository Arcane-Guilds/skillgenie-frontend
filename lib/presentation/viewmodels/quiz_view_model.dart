import 'package:flutter/material.dart';
import 'package:skillGenie/core/constants/api_constants.dart';
import 'package:skillGenie/data/models/evaluation_question.dart';
import 'package:skillGenie/data/models/quiz_question.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuizViewModel extends ChangeNotifier {
  // Add evaluation question property  
  List<EvaluationQuestion> _evaluationQuestions = [];
  bool _isGeneratingEvaluation = false;
  String? _evaluationError;

  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, String> _answers = {};
  int _currentQuestionIndex = 0;

  // Add userId property
  late final String userId;

  // Constructor to accept userId
  QuizViewModel({required this.userId});

  List<QuizQuestion> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<int, String> get answers => _answers;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _questions.length;
  double get progress => totalQuestions > 0 
      ? (_currentQuestionIndex + 1) / totalQuestions 
      : 0;

  QuizQuestion? get currentQuestion => 
    _questions.isNotEmpty && _currentQuestionIndex < _questions.length
      ? _questions[_currentQuestionIndex]
      : null;

  List<EvaluationQuestion> get evaluationQuestions => _evaluationQuestions;
  bool get isGeneratingEvaluation => _isGeneratingEvaluation;
  String? get evaluationError => _evaluationError;

  double? _evaluationScore;
  bool _isSubmittingEvaluation = false;
  String? _submissionError;

  double? get evaluationScore => _evaluationScore;
  bool get isSubmittingEvaluation => _isSubmittingEvaluation;
  String? get submissionError => _submissionError;

  Future<void> fetchQuizQuestions() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentQuestionIndex = 0; // Reset index when fetching new questions
      notifyListeners();

      final response = await http.get(Uri.parse(ApiConstants.fetchQuizQuestions));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        _questions = jsonResponse.map((question) => QuizQuestion.fromJson(question)).toList();
        
        if (_questions.isEmpty) {
          _errorMessage = 'No questions available';
        }
      } else {
        throw Exception('Failed to load quiz questions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _evaluationError = e.toString();
      notifyListeners();
      print('Error fetching quiz questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAnswer(int questionId, String answer) {
    _answers[questionId] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<bool> submitQuiz() async {
    try {
      final payload = {
        'userId': userId, // Use the userId passed to the constructor
        'learningStyle': _answers[1] ?? '',
        'skill': _answers[2] ?? '',
        'learningPreference': _answers[3] ?? '',
        'skillLevel': _answers[4] ?? '',
        'motivation': _answers[5] ?? '',
        'projectInspiration': _answers[6] ?? '',
        'learningPace': _answers[7] ?? '',
      };

      final response = await http.post(
        Uri.parse(ApiConstants.submitQuiz),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final quizResultId = responseData['_id'];
        await generateEvaluationTest(quizResultId);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Submission failed: ${e.toString()}';
      return false;
    }
  }

  Future<void> generateEvaluationTest(String quizResultId) async {
    try {
      _isGeneratingEvaluation = true;
      _evaluationError = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(ApiConstants.generateEvaluationTest),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quizResultId': quizResultId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body);
        _evaluationQuestions = data
            .map((json) => EvaluationQuestion.fromJson(json))
            .toList();
        
        if (_evaluationQuestions.isEmpty) {
          _evaluationError = 'No evaluation questions generated';
        }
      } else {
        _evaluationError = 'Failed to generate evaluation: ${response.statusCode}';
      }
    } catch (e) {
      _evaluationError = 'Evaluation error: ${e.toString()}';
    } finally {
      _isGeneratingEvaluation = false;
      notifyListeners();
    }
  }

   Future<void> submitEvaluation(String testId, String userId, List<String> answers) async {
  _isSubmittingEvaluation = true;
  _submissionError = null;
  notifyListeners();

  try {
    final response = await http.post(
      Uri.parse(ApiConstants.submitEvaluation),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'testId': testId,
        'userId': userId,
        'answers': answers,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      _evaluationScore = responseData['score']?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to submit evaluation: ${response.statusCode}');
    }
  } catch (e) {
    _submissionError = e.toString();
  } finally {
    _isSubmittingEvaluation = false;
    notifyListeners();
  }
}

  void clearEvaluation() {
    _evaluationQuestions.clear();
    _evaluationError = null;
    notifyListeners();
  }

  Future<void> reloadEvaluation() async {
    if (_evaluationQuestions.isNotEmpty) {
      final quizResultId = _evaluationQuestions.first.testId; // Assuming you have a way to get the quiz result ID
      await generateEvaluationTest(quizResultId);
    }
  }
}