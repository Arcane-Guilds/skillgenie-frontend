import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/highlight.dart' show Mode;

import '../../../data/models/evaluation_question.dart';
import '../../viewmodels/quiz_viewmodel.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../widgets/avatar_widget.dart';

class EvaluationScreen extends StatefulWidget {
  final List<EvaluationQuestion> questions;
  final String userId;

  const EvaluationScreen({super.key, required this.questions, required this.userId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  // Use a unique key for each question (combination of question ID and index)
  final Map<String, String> _answers = {};
  final Map<String, CodeController> _codeControllers = {};
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Helper method to generate a unique key for each question
  String _getQuestionKey(int questionId, int index) {
    return 'q_${questionId}_$index';
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize code controllers for code questions
    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      if (question.type == 'code') {
        final key = _getQuestionKey(question.id, i);
        _codeControllers[key] = CodeController(
          text: '',
          language: _getLanguageMode(question.language),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _codeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation Test'),
      ),
      body: Form(
        key: _formKey,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.questions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final question = widget.questions[index];
            return _buildQuestionCard(question, index);
          },
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildQuestionCard(EvaluationQuestion question, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (question.codeSnippet != null && question.codeSnippet!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCodeSnippet(question.codeSnippet!),
            ],
            const SizedBox(height: 16),
            _buildAnswerField(question, index),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF282A36), // Dracula theme background
      ),
      padding: const EdgeInsets.all(8),
      child: CodeTheme(
        data: CodeThemeData(styles: draculaTheme),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerField(EvaluationQuestion question, int index) {
    final String questionKey = _getQuestionKey(question.id, index);
    
    if (question.type == 'code') {
      // Get the code controller for this question
      final codeController = _codeControllers[questionKey]!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Answer:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: CodeTheme(
              data: CodeThemeData(styles: draculaTheme),
              child: CodeField(
                controller: codeController,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                onChanged: (value) {
                  _answers[questionKey] = value;
                },
              ),
            ),
          ),
        ],
      );
    } else {
      // Multiple choice or text input
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Answer:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (question.options.isNotEmpty)
            ...question.options.map((option) => _buildOptionRadio(questionKey, option)),
          if (question.options.isEmpty)
            TextFormField(
              initialValue: _answers[questionKey],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your answer here',
              ),
              maxLines: 3,
              onChanged: (value) {
                _answers[questionKey] = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an answer';
                }
                return null;
              },
            ),
        ],
      );
    }
  }

  Widget _buildOptionRadio(String questionKey, String option) {
    return RadioListTile<String>(
      title: Text(option),
      value: option,
      groupValue: _answers[questionKey],
      onChanged: (value) {
        setState(() {
          _answers[questionKey] = value!;
        });
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<QuizViewModel>(
      builder: (context, quizVM, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSubmitting || quizVM.isSubmittingEvaluation
                ? null
                : () => _submitEvaluation(quizVM),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting || quizVM.isSubmittingEvaluation
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text(
                    'Submit Evaluation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _submitEvaluation(QuizViewModel quizVM) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // For code questions, get the latest value from controllers
      for (var entry in _codeControllers.entries) {
        _answers[entry.key] = entry.value.text;
      }

      // Convert answers to list format expected by API
      final List<String> answersList = [];
      for (int i = 0; i < widget.questions.length; i++) {
        final question = widget.questions[i];
        final key = _getQuestionKey(question.id, i);
        answersList.add(_answers[key] ?? '');
      }

      // Submit evaluation
      await quizVM.submitEvaluation(
        widget.questions.first.testId,
        widget.userId,
        answersList,
      );

      if (mounted) {
        if (quizVM.submissionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${quizVM.submissionError}')),
          );
        } else {
          // Show generating course dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GenieAvatar(
                    state: AvatarState.thinking,
                    size: 100,
                  ),
                  SizedBox(height: 16),
                  Text('Generating your personalized learning path...'),
                ],
              ),
            ),
          );
          
          // Generate course based on quiz result
          final courseVM = Provider.of<CourseViewModel>(context, listen: false);
          
          try {
            // Generate course using the user ID
            final course = await courseVM.generateCourse(widget.userId);
            
            // Close the generating course dialog
            if (mounted) {
              Navigator.pop(context);
            }
            
            if (course != null && mounted) {
              // Navigate to home immediately after generation
              context.go('/home');
            }
          } catch (e) {
            // Close the generating course dialog
            if (mounted) {
              Navigator.pop(context);
            }
            
            // Show error dialog
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to generate course: $e')),
              );
              
              // Navigate to home even if course generation fails
              context.go('/home');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Helper method to convert language string to Mode object
  Mode? _getLanguageMode(String? languageStr) {
    switch (languageStr?.toLowerCase()) {
      case 'dart':
        return dart;
      case 'javascript':
      case 'js':
        return javascript;
      case 'python':
      case 'py':
        return python;
      default:
        return dart; // Default to dart if language is not specified or not supported
    }
  }
} 