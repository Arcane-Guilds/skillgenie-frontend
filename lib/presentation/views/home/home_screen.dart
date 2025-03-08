import 'package:flutter/material.dart';
import 'package:skillGenie/core/widgets/buttom_custom_navbar.dart';

import 'package:skillGenie/presentation/views/home/home_content.dart';
import 'package:skillGenie/presentation/views/lesson/lesson_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../data/models/user_model.dart';
import '../chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString("user");

    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      return user.username;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String?>(
          future: getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Hello, ...", style: TextStyle(fontSize: 16, color: Colors.grey));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text("Hello, Guest", style: TextStyle(fontSize: 16, color: Colors.grey));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello,",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  snapshot.data!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: const HomeContent(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
            },
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.assistant, size: 28),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  LessonView()),
              );
            },
            backgroundColor: Colors.blue, // Couleur différente pour le distinguer
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.school, size: 28),
          ),
        ],
      ),
    );
  }
}
