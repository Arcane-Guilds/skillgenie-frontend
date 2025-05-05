import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/chatbot_repository.dart';
import '../../data/models/chat_message.dart';

/// ViewModel for Chatbot functionality
class ChatbotViewModel extends ChangeNotifier {
  final ChatbotRepository _chatbotRepository;
  final ImagePicker _imagePicker = ImagePicker();

  // RegExp for coding-related topics
  final RegExp _codingRegex = RegExp(
    r'\b(programming|flutter|java|python|dart|code|coding|algorithm|function|variable|class|loop|AI|widget|repository|ViewModel)\b',
    caseSensitive: false,
  );


  List<ChatMessage> _chatHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showTypingAnimation = false;

  ChatbotViewModel({required ChatbotRepository chatbotRepository})
      : _chatbotRepository = chatbotRepository {
    // Initialize chat history when view model is created
    _initializeChatHistory();
  }

  // Getters
  List<ChatMessage> get chatHistory => _chatHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showTypingAnimation => _showTypingAnimation;

  // Initialize chat history
  Future<void> _initializeChatHistory() async {
    await loadChatHistory();
  }

  // Load chat history
  Future<void> loadChatHistory() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _chatHistory = await _chatbotRepository.getChatHistory();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load chat history: ${e.toString()}');
    }
  }

  // Helper method to set error
  void _setError(String message) {
    _errorMessage = message;
    // Auto-clear error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (_errorMessage == message) {
        _errorMessage = null;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  // Send text message
  Future<void> sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Filter non-coding-related messages
    if (!_codingRegex.hasMatch(message)) {
      _errorMessage = "I'm not Trained for this topic.";
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // Add user message to local state immediately for UI responsiveness
      final userMessage = ChatMessage(
        isPrompt: true,
        message: message,
        time: DateTime.now(),
      );

      _chatHistory.add(userMessage);
      notifyListeners();

      // Use repository to send message and get response
      final aiMessage = await _chatbotRepository.sendTextMessage(message);

      // Set animation state to true when a new AI message is received
      _showTypingAnimation = true;

      // Add AI response to local cache first (it will be animated)
      _chatHistory.add(aiMessage);

      // Update loading state
      _setLoading(false);

      // No need to reload the chat history after a successful message
      // as we already have the correct state in memory
    } on SocketException catch (e) {
      // Handle network errors
      _setError('Network connectivity issue. Please check your internet connection.');
      debugPrint('Socket Exception: $e');
      _setLoading(false);
    } catch (e) {
      _setError('Error sending message: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Mark the typing animation as complete
  void setTypingAnimationComplete() {
    _showTypingAnimation = false;
    notifyListeners();
  }

  // Pick and send image
  Future<void> pickAndSendImage() async {
    _errorMessage = null;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        _setLoading(true);

        // Add user message with image to local state immediately for UI responsiveness
        final userMessage = ChatMessage(
          isPrompt: true,
          message: "[Image Sent]",
          time: DateTime.now(),
          imagePath: pickedFile.path,
        );

        _chatHistory.add(userMessage);
        notifyListeners();

        // Use repository to send image and get response
        final aiMessage = await _chatbotRepository.sendImage(File(pickedFile.path));

        // Set animation state to true when a new AI message is received
        _showTypingAnimation = true;

        // Add AI response to local cache first (it will be animated)
        _chatHistory.add(aiMessage);

        // Update loading state
        _setLoading(false);

        // No need to reload the chat history after a successful image send
        // as we already have the correct state in memory
      }
    } on SocketException catch (e) {
      // Handle network errors
      _setError('Network connectivity issue. Please check your internet connection.');
      debugPrint('Socket Exception: $e');
      _setLoading(false);
    } catch (e) {
      _setError('Error processing image: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Clear chat history
  Future<void> clearChatHistory() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _chatbotRepository.clearChatHistory();
      _chatHistory = [];
      _showTypingAnimation = false;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError('Error clearing chat history: ${e.toString()}');
    }
  }


  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

} 