import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skillGenie/presentation/widgets/avatar_widget.dart';

class GenieStoryScreen extends StatefulWidget {
  const GenieStoryScreen({super.key});

  @override
  State<GenieStoryScreen> createState() => _GenieStoryScreenState();
}

class _GenieStoryScreenState extends State<GenieStoryScreen> {
  final List<String> _story = [
    "Hi, I'm Genie!",
    "I'm your magical learning companion.",
    "Together, we'll explore new skills, play games, and have fun!",
    "Ready to start your adventure?",
  ];
  int _current = 0;

  void _next() {
    if (_current < _story.length - 1) {
      setState(() => _current++);
    } else {
      // Go to signup or login
      context.go('/signup'); // or '/login'
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GenieAvatar(
              state: AvatarState.explaining,
              size: 180,
              message: _story[_current],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _next,
              child: Text(_current < _story.length - 1 ? "Next" : "Let's Go!"),
            ),
          ],
        ),
      ),
    );
  }
}
