import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import '../../core/constants/chatbot_constants.dart';

/// Remote data source for Chatbot AI API calls
class ChatbotRemoteDataSource {
  final String _apiKey;
  final Logger _logger = Logger('ChatbotRemoteDataSource');
  late final GenerativeModel _model;

  ChatbotRemoteDataSource({required String apiKey}) : _apiKey = apiKey {
    try {
      _model = GenerativeModel(model: ChatbotConstants.textModel, apiKey: _apiKey);
      _logger.info('Initialized Gemini model with API key');
    } catch (e) {
      _logger.severe('Failed to initialize Gemini model: $e');
      rethrow;
    }
  }

  /// Send a text message to the Gemini AI and get a response
  Future<String> sendTextMessage(String message) async {
    try {
      _logger.info('Sending text message to Gemini AI');
      
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        _logger.warning('Received empty response from Gemini AI');
        return 'Sorry, I couldn\'t generate a response. Please try again.';
      }
      
      _logger.info('Received response from Gemini AI');
      return response.text!;
    } catch (e) {
      _logger.severe('Error sending text message to Gemini AI: $e');
      return 'Error: ${e.toString()}';
    }
  }

  /// Send an image with optional text to the Gemini AI and get a response
  Future<String> sendImageMessage(File image, String? message) async {
    try {
      _logger.info('Sending image message to Gemini AI');
      
      // Convert image to base64
      final List<int> imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      // Create content with the image description request
      final content = [
        Content.text("Describe this image: $base64Image")
      ];
      
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        _logger.warning('Received empty response from Gemini AI for image');
        return 'Sorry, I couldn\'t analyze this image. Please try another one.';
      }
      
      _logger.info('Received response from Gemini AI for image');
      return response.text!;
    } catch (e) {
      _logger.severe('Error sending image message to Gemini AI: $e');
      return 'Error processing image: ${e.toString()}';
    }
  }

  /// Generate text response from Chatbot AI
  Future<String> generateTextResponse(String prompt) async {
    return sendTextMessage(prompt);
  }

  /// Generate image description from Chatbot AI
  Future<String> generateImageDescription(File imageFile) async {
    return sendImageMessage(imageFile, null);
  }

  /// Generate response for a chat history
  Future<String> generateChatResponse(List<ChatMessage> chatHistory) async {
    try {
      _logger.info('Generating chat response for ${chatHistory.length} messages');
      
      // For simplicity, just use the last message from the user
      String lastUserMessage = "";
      for (int i = chatHistory.length - 1; i >= 0; i--) {
        if (chatHistory[i].isPrompt) {
          lastUserMessage = chatHistory[i].message;
          break;
        }
      }
      
      if (lastUserMessage.isEmpty) {
        return "I don't have a message to respond to.";
      }
      
      return sendTextMessage(lastUserMessage);
    } catch (e) {
      _logger.severe('Error generating chat response: $e');
      return 'Error: ${e.toString()}';
    }
  }
} 