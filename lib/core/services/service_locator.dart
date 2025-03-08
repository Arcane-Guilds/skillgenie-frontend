import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/chatbot_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/datasources/chatbot_remote_datasource.dart';
import '../../data/datasources/chatbot_local_datasource.dart';
import '../constants/api_constants.dart';
import '../constants/cloudinary_constants.dart';
import '../constants/chatbot_constants.dart';
import '../services/storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/api_client.dart';

import '../../presentation/viewmodels/auth/auth_viewmodel.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';
import '../../presentation/viewmodels/game/game_viewmodel.dart';
import '../../presentation/viewmodels/auth/signup_viewmodel.dart';
import '../../presentation/viewmodels/quiz_view_model.dart';
import '../../presentation/viewmodels/lesson_view_model.dart';
import '../../presentation/viewmodels/chatbot_viewmodel.dart';

final serviceLocator = GetIt.instance;

/// Initialize all dependencies in the service locator
Future<void> setupServiceLocator() async {
  // External dependencies
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);
  serviceLocator.registerSingleton<http.Client>(http.Client());
  serviceLocator.registerSingleton<FlutterTts>(FlutterTts());

  // Data sources
  serviceLocator.registerSingleton<ApiClient>(ApiClient());
  
  // Auth data sources
  serviceLocator.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSource(apiClient: serviceLocator<ApiClient>()),
  );
  serviceLocator.registerSingleton<AuthLocalDataSource>(
    AuthLocalDataSource(prefs: serviceLocator<SharedPreferences>()),
  );
  
  // Profile data sources
  serviceLocator.registerSingleton<ProfileRemoteDataSource>(
    ProfileRemoteDataSource(apiClient: serviceLocator<ApiClient>()),
  );
  serviceLocator.registerSingleton<ProfileLocalDataSource>(
    ProfileLocalDataSource(prefs: serviceLocator<SharedPreferences>()),
  );
  
  // Chatbot data sources
  serviceLocator.registerSingleton<ChatbotRemoteDataSource>(
    ChatbotRemoteDataSource(apiKey: ChatbotConstants.apiKey),
  );
  serviceLocator.registerSingleton<ChatbotLocalDataSource>(
    ChatbotLocalDataSource(prefs: serviceLocator<SharedPreferences>()),
  );

  // Core services
  serviceLocator.registerSingleton<AuthRepository>(
    AuthRepository(
      remoteDataSource: serviceLocator<AuthRemoteDataSource>(),
      localDataSource: serviceLocator<AuthLocalDataSource>(),
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
      remoteDataSource: serviceLocator<ProfileRemoteDataSource>(),
      localDataSource: serviceLocator<ProfileLocalDataSource>(),
      authRepository: serviceLocator<AuthRepository>(),
      storageService: serviceLocator<StorageService>(),
    ),
  );
  
  serviceLocator.registerSingleton<ChatbotRepository>(
    ChatbotRepository(
      remoteDataSource: serviceLocator<ChatbotRemoteDataSource>(),
      localDataSource: serviceLocator<ChatbotLocalDataSource>(),
    ),
  );
  
  serviceLocator.registerSingleton<QuizRepository>(
    QuizRepository(
      client: serviceLocator<http.Client>(),
    ),
  );
  
  serviceLocator.registerSingleton<GameRepository>(
    GameRepository(),
  );
  
  serviceLocator.registerSingleton<LessonRepository>(
    LessonRepository(
      flutterTts: serviceLocator<FlutterTts>(),
    ),
  );

  // ViewModels
  serviceLocator.registerFactory<AuthViewModel>(() {
    final viewModel = AuthViewModel(
      authRepository: serviceLocator<AuthRepository>(),
    );
    viewModel.checkAuthStatus();
    return viewModel;
  });

  serviceLocator.registerFactory<SignUpViewModel>(() => 
    SignUpViewModel(
      authRepository: serviceLocator<AuthRepository>(),
    )
  );

  serviceLocator.registerFactory<ProfileViewModel>(() =>
      ProfileViewModel(
        profileRepository: serviceLocator<ProfileRepository>(),
        authViewModel: serviceLocator<AuthViewModel>(),
      ),
  );
  
  serviceLocator.registerFactory<ChatbotViewModel>(() =>
      ChatbotViewModel(
        chatbotRepository: serviceLocator<ChatbotRepository>(),
      ),
  );
  
  // Game ViewModels
  serviceLocator.registerFactory<GameViewModel>(() => 
    GameViewModel(
      gameRepository: serviceLocator<GameRepository>(),
    )
  );
  
  // Lesson ViewModel
  serviceLocator.registerFactory<LessonViewModel>(() => 
    LessonViewModel(
      lessonRepository: serviceLocator<LessonRepository>(),
    )
  );

  // Register QuizViewModel factory
  serviceLocator.registerFactoryParam<QuizViewModel, String, void>(
    (userId, _) => QuizViewModel(
      userId: userId,
      quizRepository: serviceLocator<QuizRepository>(),
    ),
  );
}

/// Cleanup resources when the app is shut down
Future<void> tearDownServiceLocator() async {
  await serviceLocator.reset();
}
