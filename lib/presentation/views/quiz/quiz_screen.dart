import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/quiz_question.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/quiz_viewmodel.dart';
import '../../widgets/avatar_widget.dart';

class QuizPage extends StatelessWidget {
  final String userId;

  const QuizPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizViewModel>(
      builder: (context, quizVM, child) {
        // Error handling at top of build method
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
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildProgressHeader(quizVM, context),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQuestionCard(quizVM, context),
                              _buildMotivationalMessage(quizVM, context),
                            ],
                          ),
                        ),
                      ),
                      _buildNavigationButtons(quizVM, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Loading Screen with GenieAvatar Animation
  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GenieAvatar(
              state: AvatarState.thinking,
              size: 120,
            ),
            SizedBox(height: 24),
            Text(
              'Getting ready for your learning journey...',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationLoading(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GenieAvatar(
              state: AvatarState.thinking,
              size: 120,
            ),
            SizedBox(height: 24),
            Text(
              'Generating your personalized evaluation...',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Progress Header
  Widget _buildProgressHeader(QuizViewModel quizVM, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Skill Assessment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                'Question ${quizVM.currentQuestionIndex + 1}/${quizVM.questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: quizVM.progress,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  // Question Card
  Widget _buildQuestionCard(QuizViewModel quizVM, BuildContext context) {
    final question = quizVM.currentQuestion!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Animate(
                  effects: [
                    FadeEffect(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: index * 100),
                    ),
                    const SlideEffect(
                      begin: Offset(0, 0.3),
                      end: Offset(0, 0),
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeOutQuad,
                    ),
                  ],
                  child: _buildOptionButton(quizVM, question, option, context),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Option Button with Animated Selection
  Widget _buildOptionButton(QuizViewModel quizVM, QuizQuestion question, String option, BuildContext context) {
    final isSelected = quizVM.answers[question.id] == option;
    
    return GestureDetector(
      onTap: () {
        quizVM.setAnswer(question.id, option);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
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
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: isSelected 
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
            ),
          ],
        ),
      ),
    );
  }

  // Motivational Message
  Widget _buildMotivationalMessage(QuizViewModel quizVM, BuildContext context) {
    final messages = [
      "You're doing great! Keep going!",
      "Almost there! You're making excellent progress!",
      "Your answers help us personalize your learning experience!",
      "Every question brings you closer to your learning goals!",
      "You're on your way to becoming a coding master!"
    ];
    
    final messageIndex = (quizVM.currentQuestionIndex % messages.length);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Animate(
        effects: const [
          FadeEffect(
            duration: Duration(milliseconds: 600),
            delay: Duration(milliseconds: 400),
          ),
        ],
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: GenieAvatar(
            state: AvatarState.explaining,
            message: messages[messageIndex],
            size: 60,
            onMessageComplete: () {
              // Optional: Add any callback when the message animation completes
            },
          ),
        ),
      ),
    );
  }

  // Navigation Buttons
  Widget _buildNavigationButtons(QuizViewModel quizVM, BuildContext context) {
    final isLastQuestion = quizVM.currentQuestionIndex == quizVM.questions.length - 1;
    final hasAnswer = quizVM.answers.containsKey(quizVM.currentQuestion!.id);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (quizVM.currentQuestionIndex > 0)
            OutlinedButton(
              onPressed: () {
                quizVM.previousQuestion();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondaryColor,
                side: BorderSide(color: AppTheme.textSecondaryColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLastQuestion ? 'Submit' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLastQuestion ? Icons.check_circle_outline : Icons.arrow_forward_ios,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
