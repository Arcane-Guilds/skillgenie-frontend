import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'core/constants/api_constants.dart';
import 'core/navigation/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'core/services/profile_service.dart';
import 'core/services/storage_service.dart';


void main() {
  // Properly initialize the required services
  final http.Client client = http.Client();
  final AuthRepository authService = AuthRepository();
  const String baseUrl = ApiConstants.baseUrl; // Replace with your actual API URL

  final profileService = ProfileService(client: client, authService: authService, baseUrl: baseUrl);
  final storageService = StorageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthViewModel()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileViewModel(
            profileService: profileService,
            storageService: storageService,
            authViewModel: Provider.of<AuthViewModel>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SkillGenie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: appRouter, // Ensure this is an instance of GoRouter
    );
  }
}
