import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:skillGenie/data/repositories/achievement_repository.dart';
import 'package:skillGenie/presentation/viewmodels/chat_viewmodel.dart';

import 'core/navigation/app_router.dart';
import 'core/services/service_locator.dart';
<<<<<<< HEAD
import 'core/storage/secure_storage.dart';
import 'data/datasources/api_client.dart';
=======
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
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

import 'web_imports.dart' if (dart.library.io) 'mobile_imports.dart';

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

    if (kIsWeb) {
      configureApp();
    }

    // Load .env file
    await dotenv.load(fileName: ".env");

    // Debug: Print all env variables (remove in production)
    if (kDebugMode) {
      print('Environment variables loaded:');
      print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
    }

    await setupServiceLocator();
    await serviceLocator<NotificationService>().initialize();
    await serviceLocator<NotificationService>().requestPermissions();

<<<<<<< HEAD
    runApp(const MyApp());
  }, AppErrorHandler.handleError);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
=======

    // Verify the API base URL in development
    if (kDebugMode) {
      try {
        final apiConstantsType = serviceLocator<ChatViewModel>();
        print('API Base URL: $apiConstantsType');
      } catch (e) {
        print('Failed to print API URL: $e');
      }
    }

    runApp(MultiProvider(
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
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
          lazy: false, // Initialize immediately
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
<<<<<<< HEAD
            final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
            // Try to initialize socket connection
            //chatViewModel.refreshCurrentChat();
=======
            final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
            final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);

            // If user is already authenticated, force a reconnect
            if (authViewModel.isAuthenticated) {
              print('User already authenticated at app launch, forcing chat connection');
              // Add a small delay to ensure auth state is fully loaded
              Future.delayed(const Duration(seconds: 1), () {
                chatViewModel.reconnect();

                // Set up a periodic connection check
                Timer.periodic(const Duration(seconds: 30), (timer) {
                  if (!chatViewModel.isSocketConnected && authViewModel.isAuthenticated) {
                    print('Periodic check: socket disconnected, attempting reconnect');
                    chatViewModel.reconnect();
                  }
                });
              });
            }

            // Listen for auth state changes
            authViewModel.addListener(() {
              if (authViewModel.isAuthenticated && !chatViewModel.isSocketConnected) {
                print('Auth state changed: User authenticated, connecting socket');
                chatViewModel.reconnect();
              }
            });
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
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
<<<<<<< HEAD
=======
    ));
  }, AppErrorHandler.handleError);
}

// Development-only HTTP client that bypasses SSL certificate validation
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
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
          create: (context) => serviceLocator<ReclamationViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => serviceLocator<RatingViewModel>(),
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
            final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
            final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);

            // If user is already authenticated, force a reconnect
            if (authViewModel.isAuthenticated) {
              print('User already authenticated at app launch, forcing chat connection');
              // Add a small delay to ensure auth state is fully loaded
              Future.delayed(const Duration(seconds: 1), () {
                chatViewModel.reconnect();

                // Set up a periodic connection check
                Timer.periodic(const Duration(seconds: 30), (timer) {
                  if (!chatViewModel.isSocketConnected && authViewModel.isAuthenticated) {
                    print('Periodic check: socket disconnected, attempting reconnect');
                    chatViewModel.reconnect();
                  }
                });
              });
            }

            // Listen for auth state changes
            authViewModel.addListener(() {
              if (authViewModel.isAuthenticated && !chatViewModel.isSocketConnected) {
                print('Auth state changed: User authenticated, connecting socket');
                chatViewModel.reconnect();
              }
            });
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
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
    );
  }
}
