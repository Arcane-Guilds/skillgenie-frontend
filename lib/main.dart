import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'core/navigation/app_router.dart';
import 'core/services/service_locator.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await setupServiceLocator();

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
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SkillGenie',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}