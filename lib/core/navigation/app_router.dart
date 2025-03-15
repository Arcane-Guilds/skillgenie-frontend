import 'package:skillGenie/data/models/evaluation_question.dart';
import 'package:skillGenie/presentation/views/game/games_screens.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/summary/summary_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/quiz_viewmodel.dart';
import '../../presentation/viewmodels/auth/auth_viewmodel.dart';
import '../../presentation/views/auth/password/forgotpassword_screen.dart';
import '../../presentation/views/auth/password/otpverification_screen.dart';
import '../../presentation/views/auth/password/resetpassword_screen.dart';
import '../../presentation/views/quiz/evaluation_screen.dart';
import '../../presentation/views/quiz/quiz_screen.dart';
import '../../presentation/views/home/home_screen.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/onboarding_screen.dart';
import '../../presentation/views/auth/signup_screen.dart';
import '../../presentation/views/splash_screen.dart';
import '../../presentation/views/profile/profile_screen.dart';
import '../../presentation/views/profile/settings_screen.dart';
import '../../presentation/views/challenges/challenges_library_screen.dart';
import '../../presentation/views/notifications_screen.dart';
import '../../presentation/views/chatbot//chatbot_screen.dart';
import '../../presentation/views/course/course_detail_screen.dart';
import '../../presentation/views/course/course_roadmap_screen.dart';
import '../widgets/buttom_custom_navbar.dart';
import '../services/service_locator.dart';

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

Page<void> _buildTransitionPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: animation,
          child: child,
        ),
  );
}

// Add this helper function at the top level
String getUniqueHeroTag(String baseTag, String uniqueIdentifier) {
  return '${baseTag}_$uniqueIdentifier';
}

// Add this function to disable Hero animations during bottom tab navigation:
final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: serviceLocator<AuthViewModel>(),
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
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/quiz/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ChangeNotifierProvider(
          create: (context) => serviceLocator.get<QuizViewModel>(param1: userId)..fetchQuizQuestions(),
          child: QuizPage(userId: userId),
        );
      },
    ),
    GoRoute(
      path: '/evaluation',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return ChangeNotifierProvider(
          create: (context) => serviceLocator.get<QuizViewModel>(param1: args['userId']),
          child: EvaluationScreen(
            questions: args['questions'] as List<EvaluationQuestion>,
            userId: args['userId'] as String,
          ),
        );
      },
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) => _buildTransitionPage(const Game()),
      routes: [
        GoRoute(
          path: 'summary',
          pageBuilder: (context, state) {
            final bool won = state.extra as bool;
            return _buildTransitionPage(
              SummaryPage(
                won: won,
              ),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/chatbot',
      builder: (context, state) => const ChatbotScreen(),
    ),
    GoRoute(
      path: '/course/:courseId',
      builder: (context, state) {
        final courseId = state.pathParameters['courseId']!;
        return CourseRoadmapScreen(courseId: courseId);
      },
    ),
    GoRoute(
      path: '/course-detail/:courseId',
      builder: (context, state) {
        final courseId = state.pathParameters['courseId']!;
        final levelIndex = int.tryParse(state.uri.queryParameters['level'] ?? '');
        final chapterIndex = int.tryParse(state.uri.queryParameters['chapter'] ?? '');
        return CourseDetailScreen(
          courseId: courseId,
          initialLevelIndex: levelIndex,
          initialChapterIndex: chapterIndex,
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) {
        int index = _getTabIndex(state.fullPath ?? '/home');
        
        // Wrap child with a HeroControllerScope that suppresses Hero animations
        // between bottom nav tab transitions
        return HeroControllerScope(
          controller: HeroController(createRectTween: (begin, end) {
            // Use normal hero animation for other transitions
            return RectTween(begin: begin, end: _isBottomNavTransition(state) ? begin : end);
          }),
          child: ShellScaffold(
            currentIndex: index,
            child: child,
          ),
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
          builder: (context, state) => const ChallengesLibraryScreen(),
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

// Add this helper function to determine if it's a bottom navigation transition
bool _isBottomNavTransition(GoRouterState state) {
  final path = state.fullPath ?? '';
  return path == '/home' || 
         path == '/games' || 
         path == '/library' || 
         path == '/notifications' || 
         path == '/profile';
}

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