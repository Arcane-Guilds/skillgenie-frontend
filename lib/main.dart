import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_router.dart';
import 'core/services/service_locator.dart';
<<<<<<< HEAD
import 'core/services/notification_service.dart';
=======
>>>>>>> b38c0289152c255c87e6579a0bd195aa9b446ded
import 'core/theme/app_theme.dart';
import 'presentation/viewmodels/auth/auth_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'presentation/viewmodels/course_viewmodel.dart';
<<<<<<< HEAD
import 'presentation/viewmodels/reminder_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Ensure Flutter is initialized
=======
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
>>>>>>> b38c0289152c255c87e6579a0bd195aa9b446ded
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables first
  await dotenv.load(fileName: ".env");
  
  // Initialize dependency injection
  await setupServiceLocator();
  
<<<<<<< HEAD
  // Initialize the notification service
  await serviceLocator<NotificationService>().initialize();
  
  // Request notification permissions
  await serviceLocator<NotificationService>().requestPermissions();
  
=======
>>>>>>> b38c0289152c255c87e6579a0bd195aa9b446ded
  runApp(const MyApp());
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
<<<<<<< HEAD
        ChangeNotifierProvider(
          create: (context) => serviceLocator<ReminderViewModel>(),
        ),
=======
>>>>>>> b38c0289152c255c87e6579a0bd195aa9b446ded
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SkillGenie',
        theme: AppTheme.theme, // Use AppTheme
        routerConfig: appRouter,
      ),
    );
  }
}