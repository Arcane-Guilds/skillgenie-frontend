import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' show ClientException;
import '../models/chat_message.dart';
import '../../core/constants/chatbot_constants.dart';

/// Remote data source for Chatbot AI API calls
class ChatbotRemoteDataSource {
  final String _apiKey;
  final Logger _logger = Logger('ChatbotRemoteDataSource');
  late final GenerativeModel? _model;
  final Connectivity _connectivity = Connectivity();

  ChatbotRemoteDataSource({required String apiKey}) : _apiKey = apiKey {
    try {
      _model = GenerativeModel(model: ChatbotConstants.textModel, apiKey: _apiKey);
      _logger.info('Initialized Gemini model with API key');
    } catch (e) {
      _logger.severe('Failed to initialize Gemini model: $e');
      _model = null;
    }
  }

  /// Check network connectivity before making API calls
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      _logger.warning('Failed to check connectivity: $e');
      return false;
    }
  }

  /// Send a text message to the Gemini AI and get a response
  Future<String> sendTextMessage(String message) async {
    try {
      // First check for connectivity
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        _logger.warning('No internet connection available');
        return 'I cannot process your request right now. Please check your internet connection and try again.';
      }
      
      // Check if model is properly initialized
      if (_model == null) {
        _logger.warning('Gemini model not initialized');
        return 'Sorry, the AI service is currently unavailable. Please try again later.';
      }
      
      _logger.info('Sending text message to Gemini AI');
      
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        _logger.warning('Received empty response from Gemini AI');
        return 'Sorry, I couldn\'t generate a response. Please try again.';
      }
      
      _logger.info('Received response from Gemini AI');
      return response.text!;
    } on SocketException catch (e) {
      _logger.severe('Network error when connecting to Gemini AI: $e');
      return 'I\'m having trouble connecting to my knowledge source. Please check your internet connection and try again.';
    } on ClientException catch (e) {
      _logger.severe('Client error when connecting to Gemini AI: $e');
      return 'I encountered a connection issue. Please try again in a moment.';
    } catch (e) {
      _logger.severe('Error sending text message to Gemini AI: $e');
      return 'I ran into a technical issue. Please try asking your question differently or try again later.';
    }
  }

  /// Send an image with optional text to the Gemini AI and get a response
  Future<String> sendImageMessage(File image, String? message) async {
    try {
      // First check for connectivity
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        _logger.warning('No internet connection available for image processing');
        return 'I cannot analyze this image right now. Please check your internet connection and try again.';
      }
      
      // Check if model is properly initialized
      if (_model == null) {
        _logger.warning('Gemini model not initialized for image processing');
        return 'Sorry, the AI image analysis service is currently unavailable. Please try again later.';
      }
      
      _logger.info('Sending image message to Gemini AI');
      
      // Convert image to base64
      final List<int> imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      // Create content with the image description request
      final content = [
        Content.text("Describe this image in detail: $base64Image")
      ];
      
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        _logger.warning('Received empty response from Gemini AI for image');
        return 'Sorry, I couldn\'t analyze this image. Please try another one.';
      }
      
      _logger.info('Received response from Gemini AI for image');
      return response.text!;
    } on SocketException catch (e) {
      _logger.severe('Network error when sending image to Gemini AI: $e');
      return 'I\'m having trouble processing this image due to connectivity issues. Please check your internet connection and try again.';
    } on ClientException catch (e) {
      _logger.severe('Client error when sending image to Gemini AI: $e');
      return 'I encountered a connection issue while analyzing the image. Please try again in a moment.';
    } catch (e) {
      _logger.severe('Error sending image message to Gemini AI: $e');
      return 'I ran into a technical issue while processing this image. Please try again later.';
    }
  }

  /// Generate response for a chat history
  Future<String> generateChatResponse(List<ChatMessage> chatHistory) async {
    try {
      // First check for connectivity
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        _logger.warning('No internet connection available for chat response');
        return 'I cannot respond right now. Please check your internet connection and try again.';
      }
      
      _logger.info('Generating chat response for ${chatHistory.length} messages');
      
      // Format the chat history into a conversation for context
      final StringBuilder sb = StringBuilder();
      
      for (final message in chatHistory.take(10)) { // Take the last 10 messages
        final sender = message.isPrompt ? "User" : "Assistant";
        sb.writeln("$sender: ${message.message}");
      }
      
      sb.writeln("Assistant: ");
      
      _logger.info('Sending chat history to Gemini API');
      return sendTextMessage(sb.toString());
    } catch (e) {
      _logger.severe('Error generating chat response: $e');
      return 'I\'m having trouble processing our conversation. Let\'s start fresh with a new question.';
    }
  }
}

/// Simple string builder
class StringBuilder {
  final StringBuffer _buffer = StringBuffer();
  
  void write(String text) {
    _buffer.write(text);
  }
  
  void writeln(String text) {
    _buffer.writeln(text);
  }
  
  @override
  String toString() {
    return _buffer.toString();
  }
} 