import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillGenie/presentation/viewmodels/chat_viewmodel.dart';

import 'core/navigation/app_router.dart';
import 'core/services/service_locator.dart';
import 'core/storage/secure_storage.dart';
import 'data/datasources/api_client.dart';  

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/repositories/friend_repository.dart';
import 'presentation/viewmodels/auth/auth_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'presentation/viewmodels/course_viewmodel.dart';
import 'presentation/viewmodels/lab_viewmodel.dart';
import 'presentation/viewmodels/community_viewmodel.dart';
import 'presentation/viewmodels/friend_viewmodel.dart';
import 'presentation/viewmodels/reminder_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/viewmodels/reclamation_viewmodel.dart';

// Conditionally import web plugins only on web platform
// This prevents dart:ui_web errors on mobile platforms
import 'web_imports.dart' if (dart.library.io) 'mobile_imports.dart';

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

    // Configure for web - use path URL strategy for cleaner URLs
    if (kIsWeb) {
      configureApp(); // This function is defined in web_imports.dart or mobile_imports.dart
    }

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
        ChangeNotifierProvider(
          create: (context) => serviceLocator<FriendViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (context) => serviceLocator<ChatViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ReclamationViewModel(context.read<AuthViewModel>()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SkillGenie',
        theme: AppTheme.theme, // Use AppTheme
        routerConfig: appRouter,
        // Add restorationScopeId to help with state restoration
        restorationScopeId: 'app',
        //navigatorKey: AppLogo.globalKey, // Use AppLogo's global key for navigation
        builder: (context, child) {
          // Initialize socket connection when app is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
            // Try to initialize socket connection
            //chatViewModel.refreshCurrentChat();
          });
          
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
                      kDebugMode
                          ? details.exception.toString()
                          : 'An error occurred',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        try {
                          // Don't use GoRouter.of(context) here as it might not be available
                          // Instead use a Navigator to pop back or restart
                          Navigator.of(context, rootNavigator: true).pop();
                        } catch (e) {
                          print('Failed to navigate: $e');
                        }
                      },
                      child: const Text('Go Back'),
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