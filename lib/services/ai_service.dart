import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../data/datasources/chatbot_remote_datasource.dart';

class AIService {
  static ChatbotRemoteDataSource? _remoteDataSource;
  
  // Initialize the remote data source lazily
  static ChatbotRemoteDataSource get remoteDataSource {
    _remoteDataSource ??= GetIt.instance<ChatbotRemoteDataSource>();
    return _remoteDataSource!;
  }

  static Future<String> getGenieResponse({
    required String userQuestion,
    required String learningStyle,
    required String selectedSkill,
    required String skillLevel,
  }) async {
    try {
      // Create a prompt that includes the learning context
      final String contextPrompt = 
          "User question: $userQuestion\n" "Learning style: $learningStyle\n" "Skill: $selectedSkill\n" +
          "Skill level: $skillLevel\n\n" +
          "Provide a personalized learning response based on these parameters.";
      
      // Use the Gemini model through the remote data source
      return await remoteDataSource.sendTextMessage(contextPrompt);
    } catch (e) {
      debugPrint('Error in getGenieResponse: $e');
      return _getFallbackLearningResponse(userQuestion, learningStyle, selectedSkill, skillLevel);
    }
  }
  
  static Future<String> getChatbotResponse({
    required String message,
    String? contextInfo,
  }) async {
    try {
      // Enhance the message with context if provided
      final String enhancedPrompt = contextInfo != null 
          ? "Context: $contextInfo\nUser message: $message"
          : message;
      
      // Use the Gemini model through the remote data source
      return await remoteDataSource.sendTextMessage(enhancedPrompt);
    } catch (e) {
      debugPrint('Error in getChatbotResponse: $e');
      return _getFallbackChatResponse(message);
    }
  }

  static Future<String> processImageInput(String imagePath) async {
    try {
      // Use the Gemini model through the remote data source
      return await remoteDataSource.sendImageMessage(File(imagePath), null);
    } catch (e) {
      debugPrint('Error in processImageInput: $e');
      return "I encountered an issue analyzing this image. The image analysis service is currently unavailable. Please try again later when your internet connection is restored.";
    }
  }
  
  // Fallback responses when API is unavailable
  static String _getFallbackChatResponse(String message) {
    final lowercaseMessage = message.toLowerCase();
    
    if (lowercaseMessage.contains('hello') || lowercaseMessage.contains('hi')) {
      return 'Hello! I\'m currently operating in offline mode due to connection issues, but I\'ll do my best to assist you with basic responses.';
    } else if (lowercaseMessage.contains('help')) {
      return 'I can normally assist with learning new skills, answering questions, and providing resources. However, I\'m currently in offline mode with limited capabilities. Please try again when your internet connection is restored.';
    } else if (lowercaseMessage.contains('thank')) {
      return 'You\'re welcome! I\'m happy to help, even in offline mode.';
    } else if (lowercaseMessage.contains('exercise') || lowercaseMessage.contains('practice')) {
      return 'While we\'re offline, here\'s a general practice exercise: Create a small project that applies the concepts you\'ve learned recently. Start simple and gradually add more features.';
    } else if (lowercaseMessage.contains('resource') || lowercaseMessage.contains('tutorial')) {
      return 'I\'d normally provide specific resources for your query, but I\'m currently in offline mode. Generally, online documentation, tutorial videos, and practice projects are great learning resources.';
    } else {
      final List<String> fallbackResponses = [
        "I'm currently in offline mode with limited capabilities. Please check your internet connection and try again later for more personalized responses.",
        "That's an interesting question! I'd like to provide a detailed response, but I'm currently operating with limited functionality due to connection issues.",
        "I'll be able to answer this more thoroughly once your internet connection is restored. For now, I can only provide basic responses.",
        "While we're offline, I recommend exploring the app's other features that don't require an internet connection. Please try your question again later.",
      ];
      
      // Return a random fallback response
      return fallbackResponses[Random().nextInt(fallbackResponses.length)];
    }
  }
  
  static String _getFallbackLearningResponse(
    String question,
    String learningStyle,
    String skill,
    String skillLevel,
  ) {
    final List<String> visualResponses = [
      "For visual learners like you, try finding diagrams, charts, and video tutorials about $skill. These visual aids can help you understand concepts better.",
      "As a visual learner studying $skill, look for infographics and color-coded notes to help organize information in a way that works for your learning style.",
    ];
    
    final List<String> auditoryResponses = [
      "Since you learn best through listening, try finding podcasts or video lectures about $skill. You might also benefit from discussing concepts out loud.",
      "For auditory learners studying $skill, recorded lectures and group discussions can be particularly effective learning methods.",
    ];
    
    final List<String> kinestheticResponses = [
      "As a hands-on learner, you'll grasp $skill concepts better through practical exercises. Try to apply what you're learning immediately in small projects.",
      "For kinesthetic learners at the $skillLevel level in $skill, interactive tutorials and real-world practice are essential for effective learning.",
    ];
    
    final List<String> readWriteResponses = [
      "With your reading/writing learning preference, taking detailed notes and summarizing $skill concepts in your own words will be most effective.",
      "For read/write learners studying $skill, writing your own examples and explanations can significantly improve understanding and retention.",
    ];
    
    // Select appropriate response based on learning style
    List<String> styleResponses;
    if (learningStyle.toLowerCase().contains('visual')) {
      styleResponses = visualResponses;
    } else if (learningStyle.toLowerCase().contains('audit')) {
      styleResponses = auditoryResponses;
    } else if (learningStyle.toLowerCase().contains('kinest')) {
      styleResponses = kinestheticResponses;
    } else {
      styleResponses = readWriteResponses;
    }
    
    // Add a note about offline mode
    const String offlineNote = "\n\nNote: I'm currently providing limited responses due to connection issues. For more personalized guidance, please try again when your internet connection is restored.";
    
    // Return a random response for the learning style plus the offline note
    return styleResponses[Random().nextInt(styleResponses.length)] + offlineNote;
  }
} 