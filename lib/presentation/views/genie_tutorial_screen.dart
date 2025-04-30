import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skillGenie/presentation/widgets/avatar_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenieTutorialScreen extends StatefulWidget {
  const GenieTutorialScreen({super.key});

  @override
  State<GenieTutorialScreen> createState() => _GenieTutorialScreenState();
}

class _GenieTutorialScreenState extends State<GenieTutorialScreen> {
  final List<_TutorialStep> _steps = [
    const _TutorialStep(
      message: "Welcome to your SkillGenie dashboard! 🏠",
      screen: '/home',
    ),
    const _TutorialStep(
      message: "Here you can track your course progress and see your learning streak.",
      screen: '/home',
    ),
    const _TutorialStep(
      message: "Let's check out some fun games to boost your skills! 🎮",
      screen: '/games',
    ),
    const _TutorialStep(
      message: "Earn coins by playing games and use them in the marketplace! 🛒",
      screen: '/games',
    ),
    const _TutorialStep(
      message: "You can always chat with me, Genie, for help or tips! 💬",
      screen: '/chatbot',
    ),
    const _TutorialStep(
      message: "Ready to start your journey? Let's go!",
      screen: '/home',
    ),
  ];

  int _current = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkHideTutorial();
  }

  Future<void> _checkHideTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hide = prefs.getBool('hide_genie_tutorial') ?? false;
    if (hide) {
      // If user chose to hide, go to home
      if (mounted) context.go('/home');
    } else {
      // Otherwise, show tutorial and go to first screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(_steps[_current].screen);
        setState(() => _loading = false);
      });
    }
  }

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_genie_tutorial', true);
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_current < _steps.length - 1) {
      setState(() {
        _current++;
        context.go(_steps[_current].screen);
      });
    } else {
      _finishTutorial();
    }
  }

  void _skip() {
    _finishTutorial();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GenieAvatar(
              state: AvatarState.explaining,
              size: 180,
              message: _steps[_current].message,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_current < _steps.length - 1)
                  TextButton(
                    onPressed: _skip,
                    child: const Text("Don't show again"),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _next,
                  child: Text(_current < _steps.length - 1 ? "Next" : "Finish"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  final String message;
  final String screen;
  const _TutorialStep({required this.message, required this.screen});
}
