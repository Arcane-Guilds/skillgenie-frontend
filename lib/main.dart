import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:skillGenie/data/repositories/achievement_repository.dart';
import 'package:skillGenie/presentation/viewmodels/chat_viewmodel.dart';

import 'core/navigation/app_router.dart';
import 'core/services/service_locator.dart';
import 'core/storage/secure_storage.dart';
import 'data/datasources/api_client.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/viewmodels/auth/auth_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'presentation/viewmodels/course_viewmodel.dart';
import 'presentation/viewmodels/lab_viewmodel.dart';
import 'presentation/viewmodels/community_viewmodel.dart';
import 'presentation/viewmodels/friend_viewmodel.dart';
import 'presentation/viewmodels/reminder_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/viewmodels/reclamation_viewmodel.dart';

// Stripe import
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

// import 'web_imports.dart' if (dart.library.io) 'mobile_imports.dart';  // Comment out web imports

class AppErrorHandler {
  static void handleError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('Global error handler caught: $error');
      print('Stack trace: $stackTrace');
    }
  }

  static void init() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        print('FlutterError: ${details.exception}');
        print('Stack trace: ${details.stack}');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        print('Uncaught exception: $error');
        print('Stack trace: $stack');
      }
      return true;
    };
  }
}

void main() async {
  AppErrorHandler.init();

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // if (kIsWeb) {  // Comment out web configuration
    //   configureApp();
    // }

    // Load .env file
    await dotenv.load(fileName: ".env");

    // Debug: Print all env variables (remove in production)
    if (kDebugMode) {
      print('Environment variables loaded:');
      print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
      print('STRIPE_PUBLISHABLE_KEY: ${dotenv.env['STRIPE_PUBLISHABLE_KEY']?.substring(0, 10)}...');
    }

    // Stripe init (non-blocking)
    try {
      final pk = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      if (pk != null && pk.isNotEmpty) {
        if (kDebugMode) print('Initializing Stripe with key: ${pk.substring(0, 10)}...');

        stripe.Stripe.publishableKey = pk;
        stripe.Stripe.merchantIdentifier = 'merchant.com.skillgenie';
        await stripe.Stripe.instance.applySettings();

        if (kDebugMode) print('✅ Stripe initialized successfully');
      } else {
        if (kDebugMode) print('⚠️ Stripe publishable key is missing or empty');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Stripe initialization failed:');
        print('Error: $e');
        print('Stack trace:\n$st');
      }
    }

    await setupServiceLocator();
    await serviceLocator<NotificationService>().initialize();
    await serviceLocator<NotificationService>().requestPermissions();

    runApp(MultiProvider(
      providers: [
        Provider<AchievementRepository>(
          create: (_) => AchievementRepository(),
        ),
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
            Provider.of<ChatViewModel>(context, listen: false);
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
    ));
  }, AppErrorHandler.handleError);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AchievementRepository>(
          create: (_) => AchievementRepository(),
        ),
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
          create: (context) => ReclamationViewModel(context.read<AuthViewModel>()),
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
            Provider.of<ChatViewModel>(context, listen: false);
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
                          if (kDebugMode) {
                            print('Failed to navigate: $e');
                          }
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