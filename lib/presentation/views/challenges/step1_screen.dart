import 'package:flutter/material.dart';
import 'package:skillGenie/core/theme/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import 'step2_screen.dart';

class Step1Screen extends StatefulWidget {
  final String name;

  const Step1Screen({super.key, required this.name});

  @override
  _Step1ScreenState createState() => _Step1ScreenState();
}

//test 
class _Step1ScreenState extends State<Step1Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.1))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          
              GenieAvatar(
                state: AvatarState.celebrating,
                size: 200,
                message: 'Let’s get this party started with ${widget.name}!',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Step2Screen(name: widget.name)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  minimumSize: const Size(140, 50),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
