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
import '../../viewmodels/quiz_view_model.dart';

class EvaluationScreen extends StatefulWidget {
  final List<EvaluationQuestion> questions;
  final String userId;

  const EvaluationScreen({super.key, required this.questions, required this.userId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final Map<int, String> _answers = {};
  final Map<int, CodeController> _codeControllers = {};
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

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
            _buildAnswerField(question),
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

  Widget _buildAnswerField(EvaluationQuestion question) {
    if (question.type == 'code') {
      // Get the appropriate language mode based on the language string
      Mode? languageMode = _getLanguageMode(question.language);
      
      // Create a code controller if it doesn't exist
      _codeControllers.putIfAbsent(
        question.id,
        () => CodeController(
          text: _answers[question.id] ?? '',
          language: languageMode,
        ),
      );

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
                controller: _codeControllers[question.id]!,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                onChanged: (value) {
                  _answers[question.id] = value;
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
          if (question.options != null && question.options!.isNotEmpty)
            ...question.options!.map((option) => _buildOptionRadio(question.id, option)),
          if (question.options == null || question.options!.isEmpty)
            TextFormField(
              initialValue: _answers[question.id],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your answer here',
              ),
              maxLines: 3,
              onChanged: (value) {
                _answers[question.id] = value;
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

  Widget _buildOptionRadio(int questionId, String option) {
    return RadioListTile<String>(
      title: Text(option),
      value: option,
      groupValue: _answers[questionId],
      onChanged: (value) {
        setState(() {
          _answers[questionId] = value!;
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
      for (var question in widget.questions) {
        answersList.add(_answers[question.id] ?? '');
      }

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
          // Navigate to results screen
          context.go('/home');
          
          // Show score in a dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Evaluation Results'),
              content: Text(
                'Your score: ${(quizVM.evaluationScore! * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 18),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
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