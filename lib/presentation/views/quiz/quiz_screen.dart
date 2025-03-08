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
              fit: BoxFit.contain,
              repeat: true,
            ),
            const Text(
              'Generating your personalized evaluation...',
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

  // Option Button with Animated Selection
  Widget _buildOptionButton(QuizViewModel quizVM, QuizQuestion question, String option) {
    final isSelected = quizVM.answers[question.id] == option;
    
    return GestureDetector(
      onTap: () {
        quizVM.setAnswer(question.id, option);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D08FF).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D08FF) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Comic Sans MS',
                  color: isSelected ? const Color(0xFF0D08FF) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D08FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Motivational Message
  Widget _buildMotivationalMessage(QuizViewModel quizVM) {
    final messages = [
      "You're doing great! Keep going!",
      "Almost there! You're making excellent progress!",
      "Your answers help us personalize your learning experience!",
      "Every question brings you closer to your learning goals!",
      "You're on your way to becoming a coding master!"
    ];
    
    final messageIndex = (quizVM.currentQuestionIndex % messages.length);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        messages[messageIndex],
        style: const TextStyle(
          fontFamily: 'Comic Sans MS',
          fontSize: 16,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Continue Button
  Widget _buildContinueButton(QuizViewModel quizVM, BuildContext context) {
    final isLastQuestion = quizVM.currentQuestionIndex == quizVM.questions.length - 1;
    final hasAnswer = quizVM.answers.containsKey(quizVM.currentQuestion!.id);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (quizVM.currentQuestionIndex > 0)
            ElevatedButton(
              onPressed: () {
                quizVM.previousQuestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, size: 16),
                  SizedBox(width: 5),
                  Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Comic Sans MS',
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 120), // Placeholder for balance
          
          ElevatedButton(
            onPressed: hasAnswer
                ? () async {
                    if (isLastQuestion) {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      
                      // Submit quiz
                      final success = await quizVM.submitQuiz();
                      
                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      
                      if (success && context.mounted) {
                        // Navigate to evaluation screen
                        context.go('/evaluation', extra: {
                          'questions': quizVM.evaluationQuestions,
                          'userId': userId,
                        });
                      }
                    } else {
                      quizVM.nextQuestion();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D08FF),
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLastQuestion ? 'Submit' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Comic Sans MS',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 