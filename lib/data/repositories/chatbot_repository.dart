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
      
      // Get AI response using chat history context for better continuity
      final responseText = await _remoteDataSource.generateChatResponse(chatHistory);
      
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
      
      // Create a fallback AI message for error cases
      final fallbackMessage = ChatMessage(
        isPrompt: false,
        message: _getFallbackErrorResponse(),
        time: DateTime.now(),
      );
      
      // Still save the fallback response to history
      try {
        final chatHistory = await _localDataSource.loadChatHistory();
        chatHistory.add(fallbackMessage);
        await _localDataSource.saveChatHistory(chatHistory);
      } catch (saveError) {
        _logger.severe('Failed to save fallback message: $saveError');
      }
      
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
      
      // Get AI response directly from the Gemini model
      final responseText = await _remoteDataSource.sendImageMessage(imageFile, null);
      
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
      
      // Create a fallback AI message for error cases
      final fallbackMessage = ChatMessage(
        isPrompt: false,
        message: "I couldn't analyze this image properly. There might be an issue with the connection or the image format.",
        time: DateTime.now(),
      );
      
      // Still save the fallback response to history
      try {
        final chatHistory = await _localDataSource.loadChatHistory();
        chatHistory.add(fallbackMessage);
        await _localDataSource.saveChatHistory(chatHistory);
      } catch (saveError) {
        _logger.severe('Failed to save fallback message: $saveError');
      }
      
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
  
  /// Get a fallback error response message
  String _getFallbackErrorResponse() {
    final List<String> fallbackResponses = [
      "I'm having trouble processing your request. Please try again in a moment.",
      "There seems to be an issue with my response system. Could you please try asking again?",
      "I apologize, but I couldn't generate a proper response. This might be due to a temporary issue.",
      "I encountered a problem while processing your request. Please try rephrasing your question.",
    ];
    
    // Return a random fallback response
    return fallbackResponses[DateTime.now().millisecondsSinceEpoch % fallbackResponses.length];
  }
} 