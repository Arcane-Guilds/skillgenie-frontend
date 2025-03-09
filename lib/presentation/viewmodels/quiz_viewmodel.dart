import 'package:flutter/material.dart';
import '../../data/models/evaluation_question.dart';
import '../../data/models/quiz_question.dart';
import '../../data/repositories/quiz_repository.dart';

class QuizViewModel extends ChangeNotifier {
  final QuizRepository _quizRepository;
  
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

  // Constructor to accept userId and repository
  QuizViewModel({
    required this.userId,
    required QuizRepository quizRepository,
  }) : _quizRepository = quizRepository;

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

      _questions = await _quizRepository.fetchQuizQuestions();
      
      if (_questions.isEmpty) {
        _errorMessage = 'No questions available';
      }
    } catch (e) {
      _errorMessage = e.toString();
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
      final quizResultId = await _quizRepository.submitQuiz(userId, _answers);
      await generateEvaluationTest(quizResultId);
      return true;
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

      _evaluationQuestions = await _quizRepository.generateEvaluationTest(quizResultId);
      
      if (_evaluationQuestions.isEmpty) {
        _evaluationError = 'No evaluation questions generated';
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
      _evaluationScore = await _quizRepository.submitEvaluation(testId, userId, answers);
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