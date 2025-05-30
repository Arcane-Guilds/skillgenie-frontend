import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:skillGenie/presentation/viewmodels/media_generator_viewmodel.dart';

import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/media_generator_repository.dart';
import '../../data/repositories/chatbot_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/datasources/chatbot_remote_datasource.dart';
import '../../data/datasources/chatbot_local_datasource.dart';
import '../constants/cloudinary_constants.dart';
import '../constants/chatbot_constants.dart';
import '../services/storage_service.dart';
import '../storage/secure_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/api_client.dart';

import '../../presentation/viewmodels/auth/auth_viewmodel.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';
import '../../presentation/viewmodels/game/game_viewmodel.dart';
import '../../presentation/viewmodels/auth/signup_viewmodel.dart';
import '../../presentation/viewmodels/quiz_viewmodel.dart';
import '../../presentation/viewmodels/chatbot_viewmodel.dart';
import '../../presentation/viewmodels/course_viewmodel.dart';
import '../../presentation/viewmodels/lab_viewmodel.dart';
import '../../presentation/viewmodels/reminder_viewmodel.dart';
import '../../presentation/viewmodels/community_viewmodel.dart';
import '../../presentation/viewmodels/friend_viewmodel.dart';
import '../services/notification_service.dart';
import '../../data/repositories/chat_repository.dart';
import '../../presentation/viewmodels/chat_viewmodel.dart';

final serviceLocator = GetIt.instance;

/// Initialize all dependencies in the service locator
Future<void> setupServiceLocator() async {
  // External dependencies
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);
  serviceLocator.registerSingleton<http.Client>(http.Client());
  serviceLocator.registerSingleton<FlutterTts>(FlutterTts());

  // Initialize and register notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  serviceLocator.registerSingleton<NotificationService>(notificationService);

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

  serviceLocator.registerSingleton<CourseRepository>(
    CourseRepository(
      client: serviceLocator<http.Client>(),
    ),
  );

  serviceLocator.registerSingleton<GameRepository>(
    GameRepository(),
  );

  serviceLocator.registerSingleton<MediaGeneratorRepository>(
    MediaGeneratorRepository(
      flutterTts: serviceLocator<FlutterTts>(),
    ),
  );


  serviceLocator.registerSingleton<CommunityRepository>(
    CommunityRepository(
      client: serviceLocator<http.Client>(),
    ),
  );

  serviceLocator.registerSingleton<LabRepository>(
    LabRepository(
      client: serviceLocator<http.Client>(),
    ),
  );

  serviceLocator.registerSingleton<FriendRepository>(
    FriendRepository(
      client: serviceLocator<http.Client>(),
    ),
  );

  // Register SecureStorage before using it in ChatRepository
  // This is critical for authentication across the app, particularly for chat functionality
  serviceLocator.registerSingleton<SecureStorage>(
    SecureStorage(serviceLocator<SharedPreferences>()),
  );

  serviceLocator.registerSingleton<ChatRepository>(
    ChatRepository(
      client: serviceLocator<http.Client>(),
      secureStorage: serviceLocator<SecureStorage>(),
    ),
  );

  // ViewModels
  // Register AuthViewModel as a Singleton to ensure it persists
  serviceLocator.registerSingletonAsync<AuthViewModel>(() async {
    final viewModel = AuthViewModel(
      authRepository: serviceLocator<AuthRepository>(),
    );
    await viewModel.checkAuthStatus(); // Wait for initial auth check
    return viewModel;
  });

  // Wait for AuthViewModel to be ready before registering dependent ViewModels
  await serviceLocator.isReady<AuthViewModel>();

  serviceLocator.registerFactory<SignUpViewModel>(() =>
      SignUpViewModel(
        authRepository: serviceLocator<AuthRepository>(),
      )
  );

  serviceLocator.registerFactory<ProfileViewModel>(() =>
      ProfileViewModel(
        profileRepository: serviceLocator<ProfileRepository>(),
        authViewModel: serviceLocator<AuthViewModel>(), // Now gets the ready Singleton
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
  serviceLocator.registerFactory<MediaGeneratorViewModel>(() =>
      MediaGeneratorViewModel(
        mediaGeneratorRepository: serviceLocator<MediaGeneratorRepository>(),
      )
  );

  // Register QuizViewModel factory
  serviceLocator.registerFactoryParam<QuizViewModel, String, void>(
        (userId, _) => QuizViewModel(
      userId: userId,
      quizRepository: serviceLocator<QuizRepository>(),
    ),
  );

  // Course ViewModel
  serviceLocator.registerFactory<CourseViewModel>(() =>
      CourseViewModel(
        courseRepository: serviceLocator<CourseRepository>(),
      ),
  );

  // Lab ViewModel
  serviceLocator.registerFactory<LabViewModel>(() =>
      LabViewModel(
        labRepository: serviceLocator<LabRepository>(),
      ),
  );

  serviceLocator.registerFactory<FriendViewModel>(() =>
      FriendViewModel(
        friendRepository: serviceLocator<FriendRepository>(),
      ),
  );

  serviceLocator.registerFactory<ReminderViewModel>(
        () => ReminderViewModel(
      notificationService: serviceLocator<NotificationService>(),
      prefs: serviceLocator<SharedPreferences>(),
    ),
  );

  serviceLocator.registerFactory<CommunityViewModel>(
        () => CommunityViewModel(
      communityRepository: serviceLocator<CommunityRepository>(),
      authViewModel: serviceLocator<AuthViewModel>(),
    ),
  );

  // Register ChatViewModel (now depends on the ready AuthViewModel Singleton)
  serviceLocator.registerFactory<ChatViewModel>(() =>
      ChatViewModel(
        chatRepository: serviceLocator<ChatRepository>(),
        secureStorage: serviceLocator<SecureStorage>(),
        authViewModel: serviceLocator<AuthViewModel>(), // Gets the ready Singleton
      ),
  );
}

/// Cleanup resources when the app is shut down
Future<void> tearDownServiceLocator() async {
  await serviceLocator.reset();
}