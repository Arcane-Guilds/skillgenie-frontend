import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// Local data source for Chatbot chat history
class ChatbotLocalDataSource {
  final SharedPreferences _prefs;
  final Logger _logger = Logger('ChatbotLocalDataSource');
  static const String _chatHistoryKey = 'chatbot_chat_history';

  ChatbotLocalDataSource({required SharedPreferences prefs}) : _prefs = prefs;

  /// Save chat history to local storage
  Future<void> saveChatHistory(List<ChatMessage> chatHistory) async {
    try {
      _logger.info('Saving chat history with ${chatHistory.length} messages');
      
      // Convert chat messages to serializable format
      List<String> serializedMessages = chatHistory.map((msg) {
        return '${msg.isPrompt}|${msg.message}|${msg.time.toIso8601String()}|${msg.imagePath ?? ""}';
      }).toList();
      
      await _prefs.setStringList(_chatHistoryKey, serializedMessages);
      _logger.info('Chat history saved successfully');
    } catch (e) {
      _logger.severe('Error saving chat history: $e');
      rethrow;
    }
  }

  /// Load chat history from local storage
  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      _logger.info('Loading chat history from local storage');
      
      final List<String>? storedHistory = _prefs.getStringList(_chatHistoryKey);
      
      if (storedHistory == null || storedHistory.isEmpty) {
        _logger.info('No chat history found in local storage');
        return [];
      }
      
      List<ChatMessage> loadedMessages = [];
      
      for (String msg in storedHistory) {
        List<String> parts = msg.split('|');
        
        // Ensure valid format (3 or 4 parts, because images might be included)
        if (parts.length >= 3) {
          bool isPrompt = parts[0] == 'true';
          String message = parts[1];
          DateTime? time;
          
          try {
            time = DateTime.parse(parts[2]);
          } catch (e) {
            _logger.warning('Invalid date format in chat history: ${parts[2]}');
            continue; // Skip invalid dates
          }
          
          String? imagePath = parts.length == 4 && parts[3].isNotEmpty ? parts[3] : null;
          
          loadedMessages.add(ChatMessage(
            isPrompt: isPrompt,
            message: message,
            time: time,
            imagePath: imagePath,
          ));
        }
      }
      
      _logger.info('Loaded ${loadedMessages.length} messages from chat history');
      return loadedMessages;
    } catch (e) {
      _logger.severe('Error loading chat history: $e');
      return [];
    }
  }

  /// Clear chat history from local storage
  Future<void> clearChatHistory() async {
    try {
      _logger.info('Clearing chat history from local storage');
      await _prefs.remove(_chatHistoryKey);
      _logger.info('Chat history cleared successfully');
    } catch (e) {
      _logger.severe('Error clearing chat history: $e');
      rethrow;
    }
  }
} 