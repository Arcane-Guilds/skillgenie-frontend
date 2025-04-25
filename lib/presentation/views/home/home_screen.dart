import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skillGenie/presentation/views/home/home_content.dart';
import 'package:skillGenie/presentation/views/chatbot/media_generator_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../data/models/user_model.dart';
import '../chatbot//chatbot_screen.dart';
import '../../../core/theme/app_theme.dart';

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
      backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.97),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<String?>(
                    future: getUsername(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.amber,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text("Hello, ...", style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.amber,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text("Hello, Guest", style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.amber,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
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
                          ),
                        ],
                      );
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main Content
            const Expanded(
              child: HomeContent(),
            ),
          ],
        ),
      ),
    );
  }
}
