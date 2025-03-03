import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/profile_repository.dart';
import '../constants/api_constants.dart';
import '../constants/cloudinary_constants.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../../data/repositories/auth_repository.dart';

import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';

final serviceLocator = GetIt.instance;

/// Initialize all dependencies in the service locator
Future<void> setupServiceLocator() async {
  // External dependencies
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);
  serviceLocator.registerSingleton<http.Client>(http.Client());

  // Core services
  serviceLocator.registerSingleton<AuthRepository>(AuthRepository());

  serviceLocator.registerSingleton<ProfileService>(
    ProfileService(
      client: serviceLocator<http.Client>(),
      authService: serviceLocator<AuthRepository>(),
      baseUrl: ApiConstants.baseUrl,
      prefs: serviceLocator<SharedPreferences>(),
    ),
  );

  serviceLocator.registerSingleton<StorageService>(
    StorageService(
      cloudName: CloudinaryConstants.cloudName,
      uploadPreset: CloudinaryConstants.uploadPreset,
    ),
  );

  // Repositories
  serviceLocator.registerSingleton<ProfileRepository>(
    ProfileRepository(
      profileService: serviceLocator<ProfileService>(),
      storageService: serviceLocator<StorageService>(),
    ),
  );

  // ViewModels
  serviceLocator.registerFactory<AuthViewModel>(() {
    final viewModel = AuthViewModel();
    viewModel.checkAuthStatus();
    return viewModel;
  });

  serviceLocator.registerFactory<ProfileViewModel>(() =>
      ProfileViewModel(
        profileRepository: serviceLocator<ProfileRepository>(),
        authViewModel: serviceLocator<AuthViewModel>(),
      ),
  );
}

/// Cleanup resources when the app is shut down
Future<void> tearDownServiceLocator() async {
  await serviceLocator.reset();
}
