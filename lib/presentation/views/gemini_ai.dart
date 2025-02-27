import 'dart:convert';  // For base64 encoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
// To get the file extension

class GeminiChatBot extends StatefulWidget {
  const GeminiChatBot({super.key});

  @override
  State<GeminiChatBot> createState() => _GeminiChatBotState();
}

class _GeminiChatBotState extends State<GeminiChatBot> {
  TextEditingController promptController = TextEditingController();
  static const apiKey = "AIzaSyCzBS8otv9A76K_hIrOwe3B1ao4KDnd0KI";
  final model = GenerativeModel(model: "gemini-pro", apiKey: apiKey);
  final ImagePicker _picker = ImagePicker();

  List<ModelMessage> prompt = [];

  @override
  void initState() {
    super.initState();
    loadChatHistory();
  }

  /// Load chat history from SharedPreferences
  Future<void> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedHistory = prefs.getStringList('chat_history');

    if (storedHistory != null) {
      List<ModelMessage> loadedMessages = [];

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
            continue; // Skip invalid dates
          }

          String? imagePath = parts.length == 4 ? parts[3] : null;

          loadedMessages.add(ModelMessage(
            isPrompt: isPrompt,
            message: message,
            time: time,
            imagePath: imagePath,
          ));
        }
      }

      setState(() {
        prompt = loadedMessages;
      });
    }
  }

  /// Save chat history to SharedPreferences
  Future<void> saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> messages = prompt.map((msg) {
      return '${msg.isPrompt}|${msg.message}|${msg.time.toIso8601String()}|${msg.imagePath ?? ""}';
    }).toList();
    await prefs.setStringList('chat_history', messages);
  }

  /// Send Text Message
  Future<void> sendMessage() async {
    final message = promptController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      prompt.add(ModelMessage(
        isPrompt: true,
        message: message,
        time: DateTime.now(),
      ));
    });

    promptController.clear();

    final content = [Content.text(message)];
    final response = await model.generateContent(content);

    setState(() {
      prompt.add(ModelMessage(
        isPrompt: false,
        message: response.text ?? "I couldn't generate a response.",
        time: DateTime.now(),
      ));
    });

    saveChatHistory();
  }

  /// Pick Image from Gallery
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Convert image to base64
      String base64Image = await convertImageToBase64(pickedFile);

      setState(() {
        prompt.add(ModelMessage(
          isPrompt: true,
          message: "[Image Sent]",
          time: DateTime.now(),
          imagePath: pickedFile.path,
        ));
      });

      // Send base64 image to AI for description
      final response = await generateImageDescription(base64Image);

      setState(() {
        prompt.add(ModelMessage(
          isPrompt: false,
          message: response ?? "Sorry, I couldn't describe the image.",
          time: DateTime.now(),
        ));
      });

      saveChatHistory();
    }
  }

  /// Convert Image to Base64
  Future<String> convertImageToBase64(XFile pickedFile) async {
    File imageFile = File(pickedFile.path);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64String = base64Encode(imageBytes);
    return base64String;
  }

  /// Generate Image Description using AI
  Future<String?> generateImageDescription(String base64Image) async {
    // Replace this with your AI call to process the image
    // For example, you might call your AI model here and send the base64 string as input.
    // In this example, we're just returning a dummy description for the image.

    final content = [
      Content.text("Describe this image: $base64Image")
    ];
    final response = await model.generateContent(content);
    return response.text;
  }

  /// Clear the conversation history
  Future<void> clearConversation() async {
    setState(() {
      prompt.clear();  // Clear the current chat
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');  // Remove the saved chat history

    // Optionally, save the empty conversation back to SharedPreferences if required
    saveChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        elevation: 3,
        backgroundColor: Colors.blue[100],
        title: const Text("Your Assistant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: clearConversation, // Button to clear conversation
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: prompt.length,
              itemBuilder: (context, index) {
                final message = prompt[index];
                return UserPrompt(
                  isPrompt: message.isPrompt,
                  message: message.message,
                  date: DateFormat('hh:mm a').format(message.time),
                  imagePath: message.imagePath,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Button to pick an image from the gallery
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.blue, size: 32),
                  onPressed: pickImage,
                ),
                Expanded(
                  flex: 20,
                  child: TextField(
                    controller: promptController,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: "Enter your text here...",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: const CircleAvatar(
                    radius: 29,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.send, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget for displaying chat messages
  Widget UserPrompt({
    required bool isPrompt,
    required String message,
    required String date,
    String? imagePath,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: isPrompt ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null) // Display image if available
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Image.file(
                File(imagePath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          Text(
            message,
            style: TextStyle(
              fontWeight: isPrompt ? FontWeight.bold : FontWeight.normal,
              fontSize: 18,
              color: isPrompt ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              color: isPrompt ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Model class for storing chat messages
class ModelMessage {
  final bool isPrompt;
  final String message;
  final DateTime time;
  final String? imagePath; // Field for images

  ModelMessage({
    required this.isPrompt,
    required this.message,
    required this.time,
    this.imagePath,
  });
}