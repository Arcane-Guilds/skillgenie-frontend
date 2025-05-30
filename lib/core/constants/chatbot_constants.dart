import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API key for Gemini AI
class ChatbotConstants {
  // API key for Gemini AI
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? "AIzaSyANQFgw4TiJSEZS0qoAwwKmFuepidBRqPE";

  // Model name - using the same as in the original implementation
  static const String textModel = "gemini-2.0-flash";
  
  // System prompt for the chatbot
  static const String systemPrompt = 
      "You are a helpful AI assistant for SkillGenie, an educational app. "
      "Provide clear, concise, and accurate information to help users learn. "
      "Be friendly and supportive.";
} 