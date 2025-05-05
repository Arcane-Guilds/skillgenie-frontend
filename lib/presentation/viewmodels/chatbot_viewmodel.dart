import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/chatbot_repository.dart';
import '../../data/models/chat_message.dart';

/// ViewModel for Chatbot functionality
class ChatbotViewModel extends ChangeNotifier {
  final ChatbotRepository _chatbotRepository;
  final ImagePicker _imagePicker = ImagePicker();
  
  List<ChatMessage> _chatHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  ChatbotViewModel({required ChatbotRepository chatbotRepository}) 
      : _chatbotRepository = chatbotRepository {
    // Initialize chat history when view model is created
    _initializeChatHistory();
  }

  // Getters
  List<ChatMessage> get chatHistory => _chatHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      _errorMessage = e.toString();
    }
  }

  // Send text message
  Future<void> sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;

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
      
      // Get AI response
      final aiMessage = await _chatbotRepository.sendTextMessage(message);
      
      // Refresh chat history to ensure consistency
      await loadChatHistory();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
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
        
        // Get AI response
        final aiMessage = await _chatbotRepository.sendImage(File(pickedFile.path));
        
        // Refresh chat history to ensure consistency
        await loadChatHistory();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
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
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 