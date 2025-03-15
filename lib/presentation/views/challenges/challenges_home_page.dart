import 'package:flutter/material.dart';

class ChallengesHomePage extends StatelessWidget {
  // Accepting a Map to hold challenge details
  final Map<String, dynamic> challenge;

  // Constructor to accept challenge details
  const ChallengesHomePage({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _nicknameController = TextEditingController();
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              challenge['image'], // Using the image passed in the challenge data
              width: 150,
              height: 100,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: TextField(
                controller: _nicknameController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'NICKNAME',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle create party button press
                        if (_nicknameController.text.isNotEmpty) {
                          // Navigate to create party screen
                          Navigator.pushNamed(
                            context,
                            '/create-party',
                            arguments: {
                              'nickname': _nicknameController.text,
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
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('CREATE PARTY'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle join party button press
                        if (_nicknameController.text.isNotEmpty) {
                          // Navigate to join party screen
                          Navigator.pushNamed(
                            context,
                            '/join-party',
                            arguments: {
                              'nickname': _nicknameController.text,
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
                      ),
                      child: const Text('JOIN PARTY'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 