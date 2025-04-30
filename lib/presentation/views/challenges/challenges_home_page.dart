import 'package:flutter/material.dart';
import '../../widgets/avatar_widget.dart';
import '../../../core/theme/app_theme.dart';

class ChallengesHomePage extends StatelessWidget {
  // Accepting a Map to hold challenge details
  final Map<String, dynamic> challenge;

  // Constructor to accept challenge details
  const ChallengesHomePage({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nicknameController = TextEditingController();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GenieAvatar(state: AvatarState.idle, size: 120),
                const SizedBox(height: 24),
                Card(
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          challenge['title'] ?? 'Challenge',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nicknameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textPrimaryColor),
                          decoration: InputDecoration(
                            hintText: 'NICKNAME',
                            hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle create party button press
                                  if (nicknameController.text.isNotEmpty) {
                                    // Navigate to create party screen
                                    Navigator.pushNamed(
                                      context,
                                      '/create-party',
                                      arguments: {
                                        'nickname': nicknameController.text,
                                        'challenge': challenge,
                                      },
                                    );
                                  } else {
                                    // Show error if nickname is empty
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a nickname'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('CREATE PARTY'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle join party button press
                                  if (nicknameController.text.isNotEmpty) {
                                    // Navigate to join party screen
                                    Navigator.pushNamed(
                                      context,
                                      '/join-party',
                                      arguments: {
                                        'nickname': nicknameController.text,
                                        'challenge': challenge,
                                      },
                                    );
                                  } else {
                                    // Show error if nickname is empty
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a nickname'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('JOIN PARTY'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 