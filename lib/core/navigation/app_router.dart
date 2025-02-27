import 'package:frontend/data/models/evaluation_question.dart';
import 'package:frontend/presentation/views/game/games_screens.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/quiz_view_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/auth/password/forgotpassword_screen.dart';
import '../../presentation/views/auth/password/otpverification_screen.dart';
import '../../presentation/views/auth/password/resetpassword_screen.dart';
import '../../presentation/views/hangman/evaluation_screen.dart';
import '../../presentation/views/hangman/quiz_screen.dart';
import '../../presentation/views/home_screen.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/onboarding_screen.dart';
import '../../presentation/views/auth/signup_screen.dart';
import '../../presentation/views/splash_screen.dart';
import '../../presentation/views/profile_screen.dart';
import '../../presentation/views/favorites_screen.dart';
import '../../presentation/views/library_screen.dart';
import '../../presentation/views/notifications_screen.dart';
import '../widgets/buttom_custom_navbar.dart';

// ShellScaffold remains the same
class ShellScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const ShellScaffold({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(currentIndex: currentIndex),
    );
  }
}

// Define navigation
final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthViewModel(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final email = (state.extra as Map<String, dynamic>)['email'] as String;
        return OtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final email = (state.extra as Map<String, dynamic>)['email'] as String;
        return ResetPasswordScreen(email: email);
      },
    ),
    //GoRoute(path:'/evaluation', builder: (context, state) => const EvaluationScreen()),
    GoRoute(
      path: '/quiz/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ChangeNotifierProvider(
          create: (context) => QuizViewModel(userId: userId)..fetchQuizQuestions(),
          child: QuizPage(userId: userId),
        );
      },
    ),
     GoRoute(
      path: '/evaluation',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return ChangeNotifierProvider(
          create: (context) => QuizViewModel(userId: args['userId']),
          child: EvaluationScreen(
            questions: args['questions'] as List<EvaluationQuestion>,
            userId: args['userId'] as String,
          ),
        );
      },
    ),

    // Shell Route for Bottom Navigation Screens
    ShellRoute(
      builder: (context, state, child) {
        int index = _getTabIndex(state.fullPath ?? '/home');

        return ShellScaffold(
          currentIndex: index,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/Games',
          builder: (context, state) => const GamesScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

// Function to determine the current tab index
int _getTabIndex(String location) {
  switch (location) {
    case '/games':
      return 1;
    case '/library':
      return 2;
    case '/notifications':
      return 3;
    case '/profile':
      return 4;
    default:
      return 0;
  }
}
