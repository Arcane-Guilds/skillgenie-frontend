import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:frontend/data/models/evaluation_question.dart';
import 'package:frontend/presentation/viewmodels/quiz_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';




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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submitEvaluation,
        icon: _isSubmitting
            ? const CircularProgressIndicator()
            : const Icon(Icons.assignment_turned_in),
        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Evaluation'),
      
        backgroundColor: const Color(0xFF0D08FF),
      ),
    );
  }

 Widget _buildQuestionCard(EvaluationQuestion question, int index) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D08FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}', // Display question number starting from 1
                  style: const TextStyle(
                    color: Color(0xFF0D08FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (question.type == 'programming')
            _buildCodeEditor(question, index) // Pass index (zero-based)
          else
            _buildMultipleChoice(question, index), // Pass index (zero-based)
        ],
      ),
    ),
  );
}

 Widget _buildMultipleChoice(EvaluationQuestion question, int index) {
  return Column(
    children: question.options.map((option) => RadioListTile<String>(
      title: Text(option),
      value: option,
      groupValue: _answers[index], // Use index (zero-based)
      onChanged: (value) => setState(() => _answers[index] = value!),
      contentPadding: EdgeInsets.zero,
    )).toList(),
  );
}

Widget _buildCodeEditor(EvaluationQuestion question, int index) {
  // Initialize the CodeController for this question if it doesn't exist
  if (!_codeControllers.containsKey(index)) {
    _codeControllers[index] = CodeController(
      text: question.codeTemplate ?? '',
    );
  }

  final codeController = _codeControllers[index]!;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Code Template:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CodeTheme(
          data: CodeThemeData(styles: draculaTheme),
          child: CodeField(
            controller: codeController,
            textStyle: const TextStyle(fontFamily: 'monospace'),
            minLines: 5,
            maxLines: 10,
            gutterStyle: const GutterStyle(
              showLineNumbers: true,
              margin: 10,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextFormField(
        onChanged: (value) => _answers[index] = value, // Use index (zero-based)
        decoration: InputDecoration(
          labelText: 'Your Answer',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your answer';
          }
          return null;
        },
      ),
    ],
  );
}

 Future<void> _submitEvaluation() async {
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fix validation errors')),
    );
    return;
  }

  for (int i = 0; i < widget.questions.length; i++) {
    if (_answers[i] == null || _answers[i]!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer question ${i + 1}')),
      );
      return;
    }
  }

  final quizVM = Provider.of<QuizViewModel>(context, listen: false);

  final formattedAnswers = List.generate(
    widget.questions.length,
    (index) => _answers[index]!,
  );

  try {
    setState(() => _isSubmitting = true);

    final testId = widget.questions.first.testId;
    final userId = widget.userId;

    if (testId.isEmpty || userId.isEmpty) {
      throw Exception('Missing test ID or user ID');
    }

    await quizVM.submitEvaluation(testId, userId, formattedAnswers);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evaluation Result'),
        content: quizVM.isSubmittingEvaluation
            ? const CircularProgressIndicator()
            : quizVM.submissionError != null
                ? Text('Error: ${quizVM.submissionError}')
                : Text('Your score: ${quizVM.evaluationScore?.toStringAsFixed(1) ?? 'N/A'}'),
        actions: [
          if (!quizVM.isSubmittingEvaluation)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              child: const Text('OK'),
            ),
        ],
      ),
    );
  } catch (e) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Submission failed: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
}