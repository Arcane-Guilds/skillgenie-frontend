import 'package:skillGenie/data/models/evaluation_question.dart';
import 'package:skillGenie/presentation/views/game/games_screens.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/summary/summary_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import '../../presentation/views/profile/friends_screen.dart';
import '../../presentation/views/challenges/challenges_library_screen.dart';
import '../../presentation/views/notifications_screen.dart';
import '../../presentation/views/chatbot/chatbot_screen.dart';
import '../../presentation/views/community/community_screen.dart';
import '../../presentation/views/community/post_detail_screen.dart';
import '../../presentation/views/course/course_detail_screen.dart';
import '../../presentation/views/course/course_roadmap_screen.dart';
import '../../presentation/views/course/lab_screen.dart';
import '../../presentation/views/chat/chat_list_screen.dart';
import '../../presentation/views/chat/chat_detail_screen.dart';
import '../../presentation/views/chat/create_chat_screen.dart';
import '../widgets/buttom_custom_navbar.dart';
import '../services/service_locator.dart';

// ShellScaffold remains the same
class ShellScaffold extends StatelessWidget {
final Widget child;
final int currentIndex;

const ShellScaffold({
super.key,
required this.child,
required this.currentIndex,
});

@override
Widget build(BuildContext context) {
  const bool isMobile = !kIsWeb;
  
  return Scaffold(
    body: child,
    bottomNavigationBar: isMobile ? CustomBottomNavBar(currentIndex: currentIndex) : null,
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
    key: UniqueKey(),
  );
}

// Add this helper function at the top level
String getUniqueHeroTag(String baseTag, String uniqueIdentifier) {
  return '${baseTag}_$uniqueIdentifier';
}

// Completely disable hero animations during bottom tab navigation
class NoHeroTheme extends InheritedWidget {
  const NoHeroTheme({
    super.key,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NoHeroTheme>() != null;
  }

  @override
  bool updateShouldNotify(NoHeroTheme oldWidget) => false;
}

// Custom observer specifically for tracking Hero animation issues
class HeroAnimationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('HeroAnimationObserver: Pushed ${route.settings.name ?? 'unnamed route'}');
    super.didPush(route, previousRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('HeroAnimationObserver: Gesture on ${route.settings.name ?? 'unnamed route'}');
    super.didStartUserGesture(route, previousRoute);
  }
}

// Add a global navigation observer to detect navigation errors
class NavigationErrorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Pushed ${route.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Popped ${route.settings.name}');
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Removed ${route.settings.name}');
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Started gesture on ${route.settings.name}');
    super.didStartUserGesture(route, previousRoute);
  }
}

// Custom Hero controller that prevents animations between navbar items
class CustomHeroController extends HeroController {
  CustomHeroController();

  final Set<String> _currentHeroTags = {};

  void registerTag(String tag) {
    _currentHeroTags.add(tag);
  }

  void clearTags() {
    _currentHeroTags.clear();
  }

  @override
  void dispose() {
    _currentHeroTags.clear();
    super.dispose();
  }

  @override
  Widget createPlatformSpecificHeroFlightShuttleBuilder(Widget child) {
    // Always use basic fade transition which is less problematic
    return FadeTransition(opacity: const AlwaysStoppedAnimation(1.0), child: child);
  }
}

// Global instance of our custom hero controller
final customHeroController = CustomHeroController();

// Add this function to disable Hero animations during bottom tab navigation:
final appRouter = GoRouter(
initialLocation: '/',
refreshListenable: serviceLocator<AuthViewModel>(),
  // Add global redirect to recover from errors
  redirect: (BuildContext context, GoRouterState state) {
    // If we detect a path that doesn't exist or has an error, redirect to home
    final bool isValidPath = state.uri.toString().isNotEmpty;
    if (!isValidPath) {
      return '/home';
    }
    return null; // return null to continue
  },
  // Add error handling for navigation
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Navigation Error'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60
          ),
          const SizedBox(height: 16),
          const Text(
            'Navigation error occurred',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).go('/home'),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
  // Add observers to track navigation
  observers: [NavigationErrorObserver(), HeroAnimationObserver()],
  // Optimize for memory and performance
  debugLogDiagnostics: kDebugMode,
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
  path: '/otp-verification/:email', // Expects email parameter
  builder: (context, state) {
    final email = state.pathParameters['email'] ?? ''; // Extract email
    return OtpVerificationScreen(email: email);
  },
),
GoRoute(
  path: '/reset-password/:email', // Expects email parameter
  builder: (context, state) {
    final email = state.pathParameters['email'] ?? ''; // Extract email
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
GoRoute(
path: '/lab/:chapterId',
builder: (context, state) {
final chapterId = state.pathParameters['chapterId']!;
return LabScreen(chapterId: chapterId);
},
),
  GoRoute(
    path: '/post/:postId',
    builder: (context, state) {
      final postId = state.pathParameters['postId']!;
      return PostDetailScreen(postId: postId);
    },
  ),
GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
    GoRoute(
      path: '/chat/detail',
      builder: (context, state) {
        final chatId = state.extra as String;
        return ChatDetailScreen(chatId: chatId);
      },
    ),
    GoRoute(path: '/chat/create', builder: (context, state) => const CreateChatScreen()),
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
path: '/games',
builder: (context, state) => const GamesScreen(),
),
GoRoute(
path: '/library',
builder: (context, state) => const ChallengesLibraryScreen(),
),
  GoRoute(
    path: '/community',
    builder: (context, state) => const CommunityScreen(),
  ),
GoRoute(
path: '/notifications',
builder: (context, state) => const NotificationsScreen(),
),
GoRoute(
path: '/profile',
builder: (context, state) => const ProfileScreen(),
),
GoRoute(
path: '/friends',
builder: (context, state) => const FriendsScreen(),
),
],
),
],
);

// Function to determine if it's a bottom navigation transition
bool _isBottomNavTransition(GoRouterState state) {
  try {
    final path = state.fullPath ?? '';
    return path.startsWith('/home') ||
           path.startsWith('/games') ||
           path.startsWith('/library') ||
           path.startsWith('/community') ||
           path.startsWith('/notifications') ||
           path.startsWith('/profile');
  } catch (e) {
    print('Error in _isBottomNavTransition: $e');
    return false;
  }
}

// Function to determine the current tab index
int _getTabIndex(String location) {
  int index = 0;

  try {
    if (location.startsWith('/games')) {
      index = 1;
    } else if (location.startsWith('/library')) {
      index = 2;
    } else if (location.startsWith('/community') || location.startsWith('/notifications')) {
      index = 3;
    } else if (location.startsWith('/profile') || location.startsWith('/friends')) {
      index = 4;
    }
  } catch (e) {
    print('Error in _getTabIndex: $e');
  }

  return index;
}
