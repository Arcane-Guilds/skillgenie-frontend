import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skillGenie/presentation/views/home/home_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/presentation/views/game/MarketplaceScreen.dart';
import 'package:skillGenie/presentation/views/news/news_screen.dart';

import '../../../data/models/user_model.dart';
import '../chatbot/chatbot_screen.dart';
import '../../widgets/avatar_widget.dart';
<<<<<<< HEAD
/* */ import '../chatbot/lesson_view.dart'; /* */

=======
import '../chatbot/lesson_view.dart';

// App-wide primary color
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
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
<<<<<<< HEAD
  bool catEquipped = false;
  Key? catGifKey;

=======
  
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
<<<<<<< HEAD

    _loadUserData();
    _setWelcomeMessage();
    _loadCatEquipped();
  }

=======
    
    _loadUserData();
    _setWelcomeMessage();
  }
  
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
<<<<<<< HEAD

=======
  
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
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
<<<<<<< HEAD
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("user");
=======
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString("user");

>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        setState(() {
          _user = user;
          _username = user.username;
<<<<<<< HEAD
        });
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCatEquipped() async {
    final prefs = await SharedPreferences.getInstance();
    final equipped = prefs.getBool('catEquipped') ?? false;
    setState(() {
      catEquipped = equipped;
      catGifKey = equipped ? UniqueKey() : null;
    });
    if (equipped) {
      PaintingBinding.instance.imageCache.clear();
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
            /* */
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text("Lesson in a video"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => LessonView()));
              },
            ),
            /* */
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text("Marketplace"),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                );
                if (result != null && result is bool) {
                  setState(() {
                    catEquipped = result;
                    catGifKey = result ? UniqueKey() : null;
                  });
                  if (result) {
                    PaintingBinding.instance.imageCache.clear();
                  }
                }
              },
            ),
          ],
        );
      },
=======
          _isLoading = false;
        });
      } else {
        setState(() {
          _user = null;
          _username = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _user = null;
        _username = null;
        _isLoading = false;
      });
    }
  }

  void _navigateToChatbot(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatbotScreen()),
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final theme = Theme.of(context);

=======
    final ThemeData theme = Theme.of(context);
    
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
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
          // Cat gif overlay (bottom left)
          if (catEquipped)
            Positioned(
              bottom: 16,
              left: 16,
              child: Image.asset(
                'assets/images/cat.gif',
                key: catGifKey,
                width: 80,
                height: 80,
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
<<<<<<< HEAD

          // Notification button
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: kPrimaryBlue),
            onPressed: () {},
          ),

          // News button
          IconButton(
            icon: const Icon(Icons.newspaper_outlined, color: kPrimaryBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewsScreen()),
              );
            },
          ),

          // Marketplace button right next to notifications
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: kPrimaryBlue),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              );
              if (result != null && result is bool) {
                setState(() {
                  catEquipped = result;
                  catGifKey = result ? UniqueKey() : null;
                });
                if (result) {
                  PaintingBinding.instance.imageCache.clear();
                }
              }
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
=======
          
          // Action buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: kPrimaryBlue,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenieSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // Genie Avatar with animation
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
          
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
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
<<<<<<< HEAD
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
=======
          ).animate().fadeIn(
            duration: 800.ms,
            delay: 200.ms,
          ),
>>>>>>> ab381aea10a277266aa2f4091b857b179b11e70e
        ],
      ),
    );
  }
}