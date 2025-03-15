import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/core/services/service_locator.dart';
import 'package:skillGenie/presentation/viewmodels/chatbot_viewmodel.dart';






class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => serviceLocator<ChatbotViewModel>(),
      child: Consumer<ChatbotViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.blue[100],
            appBar: AppBar(
              elevation: 3,
              backgroundColor: Colors.blue[100],
              title: const Text("Your Assistant"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: viewModel.clearChatHistory,
                ),
              ],
            ),
            body: Column(
              children: [
                if (viewModel.isLoading)
                  const LinearProgressIndicator(),
                  
                if (viewModel.errorMessage != null)
                  Container(
                    color: Colors.red[100],
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = viewModel.chatHistory[index];
                      return _buildChatMessage(
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
                        onPressed: viewModel.isLoading 
                            ? null 
                            : viewModel.pickAndSendImage,
                      ),
                      Expanded(
                        flex: 20,
                        child: TextField(
                          controller: _promptController,
                          style: const TextStyle(color: Colors.black, fontSize: 18),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            hintText: "Enter your text here...",
                          ),
                          enabled: !viewModel.isLoading,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: viewModel.isLoading 
                            ? null 
                            : () {
                                final message = _promptController.text.trim();
                                if (message.isNotEmpty) {
                                  viewModel.sendTextMessage(message);
                                  _promptController.clear();
                                }
                              },
                        child: CircleAvatar(
                          radius: 29,
                          backgroundColor: viewModel.isLoading 
                              ? Colors.grey 
                              : Colors.green,
                          child: const Icon(Icons.send, color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Widget for displaying chat messages
  Widget _buildChatMessage({
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