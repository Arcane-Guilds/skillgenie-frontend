import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'core/navigation/app_router.dart';
import 'core/services/service_locator.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/viewmodels/auth/auth_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'presentation/viewmodels/course_viewmodel.dart';
import 'presentation/viewmodels/lab_viewmodel.dart';
import 'presentation/viewmodels/community_viewmodel.dart';
import 'presentation/viewmodels/reminder_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppErrorHandler {
  static void handleError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('Global error handler caught: $error');
      print('Stack trace: $stackTrace');
    }
  }

  static void init() {
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Only log to console in debug mode
      if (kDebugMode) {
        print('FlutterError: ${details.exception}');
        print('Stack trace: ${details.stack}');
      }
    };

    // Handle uncaught async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      // Only log to console in debug mode
      if (kDebugMode) {
        print('Uncaught exception: $error');
        print('Stack trace: $stack');
      }
      return true; // Return true to indicate the error was handled
    };
  }
}

void main() async {
  // Initialize error handling
  AppErrorHandler.init();

  runZonedGuarded(() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables first
    await dotenv.load(fileName: ".env");

    // Initialize dependency injection
    await setupServiceLocator();

    // Initialize the notification service
    await serviceLocator<NotificationService>().initialize();

    // Request notification permissions
    await serviceLocator<NotificationService>().requestPermissions();

    runApp(const MyApp());
  }, AppErrorHandler.handleError);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => serviceLocator<AuthViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (context) => serviceLocator<ProfileViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (context) => serviceLocator<CourseViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (context) => serviceLocator<LabViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (context) => serviceLocator<ReminderViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (context) => serviceLocator<CommunityViewModel>(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SkillGenie',
        theme: AppTheme.theme, // Use AppTheme
        routerConfig: appRouter,
        // Add restorationScopeId to help with state restoration
        restorationScopeId: 'app',
        builder: (context, child) {
          // Add error handling for widget errors
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kDebugMode ? details.exception.toString() : 'An error occurred',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        try {
                          GoRouter.of(context).go('/home');
                        } catch (e) {
                          print('Failed to navigate to home: $e');
                        }
                      },
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            );
          };

          // Just return the child without another HeroControllerScope
          // Let the app_router.dart handle Hero animations
          return child!;
        },
      ),
    );
  }
}