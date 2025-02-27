import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../data/models/quiz_question.dart';
import '../../viewmodels/quiz_view_model.dart';



class QuizPage extends StatelessWidget {
  final String userId;

  const QuizPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizViewModel>(
      builder: (context, quizVM, child) {
        // Add error handling at top of build method:
        if (quizVM.evaluationError != null) {
          return _buildErrorScreen(context, quizVM.evaluationError!);
        }

        if (quizVM.isGeneratingEvaluation) {
          return _buildEvaluationLoading(context);
        }

        if (quizVM.errorMessage != null) {
          return _buildErrorScreen(context, quizVM.errorMessage!);
        }

        if (quizVM.isLoading) {
          return _buildLoadingScreen();
        }

        if (quizVM.questions.isEmpty) {
          return _buildErrorScreen(context, 'No questions available. Please try again later.');
        }

        if (quizVM.currentQuestion == null) {
          return _buildErrorScreen(context, 'Something went wrong. Please restart the quiz.');
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          body: Column(
            children: [
              _buildProgressHeader(quizVM),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOutBack,
                  child: _buildQuestionCard(quizVM, context),
                ),
              ),
              _buildMotivationalMessage(quizVM),
              _buildContinueButton(quizVM, context),
            ],
          ),
        );
      },
    );
  }

  // Loading Screen with Lottie Animation
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/images/loading.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const Text(
              'Getting ready for your learning journey...',
              style: TextStyle(
                fontFamily: 'Comic Sans MS',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/images/error.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              repeat: true,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Comic Sans MS',
                  fontSize: 18,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Call the reloadEvaluation method
                await Provider.of<QuizViewModel>(context, listen: false).reloadEvaluation();
                // Optionally, you can also fetch quiz questions again if needed
                await Provider.of<QuizViewModel>(context, listen: false).fetchQuizQuestions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D08FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Comic Sans MS',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Progress Header with Lottie Avatar and Orange Progress Bar
  Widget _buildProgressHeader(QuizViewModel quizVM) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(5),
                child: Lottie.asset(
                  'assets/images/avatar.json',
                  animate: true,
                  repeat: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: quizVM.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9500)),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${(quizVM.progress * 100).toInt()}% Complete',
            style: const TextStyle(
              fontFamily: 'Comic Sans MS',
              color: Color(0xFFFF9500),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Question Card with Lottie Feedback
  Widget _buildQuestionCard(QuizViewModel quizVM, BuildContext context) {
    final question = quizVM.currentQuestion!;
    return Transform.scale(
      scale: 0.95,
      child: Container(
        margin: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // Add max height
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                question.question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Comic Sans MS',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded( // Add Expanded here
              child: SingleChildScrollView( // Add scrollable content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...question.options.map((option) => 
                      _buildOptionButton(quizVM, question, option)),
                    const SizedBox(height: 10), // Add bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Option Button with Lottie Feedback
  Widget _buildOptionButton(QuizViewModel quizVM, QuizQuestion question, String option) {
    final isSelected = quizVM.answers[question.id] == option;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        color: isSelected ? const Color(0xFF0D08FF).withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          onTap: () => quizVM.setAnswer(question.id, option),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF0D08FF) : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Lottie.asset(
                          'assets/images/check.json',
                          width: 24,
                          height: 24,
                        )
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? const Color(0xFF0D08FF) : Colors.black,
                      fontFamily: 'Comic Sans MS',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Motivational Message with Lottie Animation
  Widget _buildMotivationalMessage(QuizViewModel quizVM) {
    final messages = [
      'You’re doing great! 🌟',
      'Keep it up! 💪',
      'Learning is fun! 🎉',
      'Awesome progress! 🚀',
      'You’re a star! ⭐️'
    ];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        key: ValueKey(quizVM.currentQuestionIndex),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Lottie.asset(
              'assets/images/motivation.json',
              width: 100,
              height: 100,
              repeat: false,
            ),
            Text(
              messages[quizVM.currentQuestionIndex % messages.length],
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFFFF9500),
                fontFamily: 'Comic Sans MS',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Continue Button with Lottie Feedback
  Widget _buildContinueButton(QuizViewModel quizVM, BuildContext context) {
  final hasAnswer = quizVM.answers.containsKey(quizVM.currentQuestion?.id);
  final isLastQuestion = quizVM.currentQuestionIndex == quizVM.questions.length - 1;

  return Container(
    margin: const EdgeInsets.all(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: hasAnswer
            ? [
                BoxShadow(
                  color: const Color(0xFF0D08FF).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D08FF),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        onPressed: hasAnswer
            ? () async {
                if (isLastQuestion) {
                  final success = await quizVM.submitQuiz();
                  if (success && context.mounted) {
                    if (quizVM.evaluationError == null) {
                      // Wait for evaluation generation to complete
                      while (quizVM.isGeneratingEvaluation) {
                        await Future.delayed(const Duration(milliseconds: 100));
                      }

                      if (quizVM.evaluationQuestions.isNotEmpty) {
                        context.push(
                          '/evaluation',
                          extra: {
                            'questions': quizVM.evaluationQuestions,
                            'userId': quizVM.userId,
                          },
                        );
                      }
                    }
                  }
                } else {
                  quizVM.nextQuestion();
                }
              }
            : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isLastQuestion ? 'Finish Learning! 🎓' : 'Continue →',
            key: ValueKey(isLastQuestion),
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Comic Sans MS',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
  Widget _buildEvaluationLoading(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/images/loading.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'AI is generating your personalized evaluation...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontFamily: 'Comic Sans MS',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              color: Color(0xFF0D08FF),
            ),
          ],
        ),
      ),
    );
  }
}