import 'dart:io';
import 'package:logging/logging.dart';
import '../datasources/chatbot_remote_datasource.dart';
import '../datasources/chatbot_local_datasource.dart';
import '../models/chat_message.dart';

/// Repository for Chatbot operations
class ChatbotRepository {
  final ChatbotRemoteDataSource _remoteDataSource;
  final ChatbotLocalDataSource _localDataSource;
  final Logger _logger = Logger('ChatbotRepository');

  ChatbotRepository({
    required ChatbotRemoteDataSource remoteDataSource,
    required ChatbotLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Send a text message and get a response
  Future<ChatMessage> sendTextMessage(String message) async {
    try {
      _logger.info('Sending text message: ${message.substring(0, message.length > 30 ? 30 : message.length)}...');
      
      // Create a user message
      final userMessage = ChatMessage(
        isPrompt: true,
        message: message,
        time: DateTime.now(),
      );
      
      // Get current chat history
      final chatHistory = await _localDataSource.loadChatHistory();
      
      // Add user message to history
      chatHistory.add(userMessage);
      
      // Get AI response
      final responseText = await _remoteDataSource.generateTextResponse(message);
      
      // Create AI response message
      final aiMessage = ChatMessage(
        isPrompt: false,
        message: responseText,
        time: DateTime.now(),
      );
      
      // Add AI message to history
      chatHistory.add(aiMessage);
      
      // Save updated chat history
      await _localDataSource.saveChatHistory(chatHistory);
      
      return aiMessage;
    } catch (e) {
      _logger.severe('Error sending text message: $e');
      rethrow;
    }
  }

  /// Send an image and get a description
  Future<ChatMessage> sendImage(File imageFile) async {
    try {
      _logger.info('Sending image for description');
      
      // Create a user message with image
      final userMessage = ChatMessage(
        isPrompt: true,
        message: "[Image Sent]",
        time: DateTime.now(),
        imagePath: imageFile.path,
      );
      
      // Get current chat history
      final chatHistory = await _localDataSource.loadChatHistory();
      
      // Add user message to history
      chatHistory.add(userMessage);
      
      // Get AI response
      final responseText = await _remoteDataSource.generateImageDescription(imageFile);
      
      // Create AI response message
      final aiMessage = ChatMessage(
        isPrompt: false,
        message: responseText,
        time: DateTime.now(),
      );
      
      // Add AI message to history
      chatHistory.add(aiMessage);
      
      // Save updated chat history
      await _localDataSource.saveChatHistory(chatHistory);
      
      return aiMessage;
    } catch (e) {
      _logger.severe('Error sending image: $e');
      rethrow;
    }
  }

  /// Load chat history
  Future<List<ChatMessage>> getChatHistory() async {
    try {
      _logger.info('Getting chat history');
      return await _localDataSource.loadChatHistory();
    } catch (e) {
      _logger.severe('Error getting chat history: $e');
      rethrow;
    }
  }

  /// Clear chat history
  Future<void> clearChatHistory() async {
    try {
      _logger.info('Clearing chat history');
      await _localDataSource.clearChatHistory();
    } catch (e) {
      _logger.severe('Error clearing chat history: $e');
      rethrow;
    }
  }
} 