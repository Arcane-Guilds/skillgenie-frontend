import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skillGenie/presentation/views/home/home_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../data/models/user_model.dart';
import '../chatbot/chatbot_screen.dart';
import '../../widgets/avatar_widget.dart';
import '../chatbot/lesson_view.dart';
import '../game/MarketplaceScreen.dart'; // Import your Marketplace screen

const Color kPrimaryBlue = Color(0xFF29B6F6);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _username;
  String _welcomeMessage = "Welcome back!";
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadUserData();
    _setWelcomeMessage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _welcomeMessage = "Good morning!";
    } else if (hour < 17) {
      _welcomeMessage = "Good afternoon!";
    } else {
      _welcomeMessage = "Good evening!";
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("user");
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        setState(() {
          _user = user;
          _username = user.username;
        });
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBottomMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text("Ask Genie"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text("Lesson in a video"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => LessonView()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text("Marketplace"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kPrimaryBlue.withOpacity(0.2), theme.scaffoldBackgroundColor],
              ),
            ),
          ),

          // Main
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(theme),
                _buildGenieSection(theme),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, -3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const HomeContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        onPressed: _showBottomMenu,
        child: const Icon(Icons.menu),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _welcomeMessage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _isLoading
                    ? SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: kPrimaryBlue.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(kPrimaryBlue),
                  ),
                )
                    : Text(
                  _username ?? "Guest",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Notification button
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: kPrimaryBlue),
            onPressed: () {},
          ),

          // Marketplace button right next to notifications
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: kPrimaryBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              );
            },
          ),

          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kPrimaryBlue),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGenieSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: GenieAvatar(
              state: AvatarState.celebrating,
              message: "Ready to continue your learning journey?",
              size: 90,
              onMessageComplete: () {},
            ),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.easeOutBack,
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, color: kPrimaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tip: Practice daily to build your skills faster!",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
        ],
      ),
    );
  }
}