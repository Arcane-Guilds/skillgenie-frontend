import 'package:flutter/material.dart';
//import 'party_code_screen.dart'; // Import the PartyCodeScreen
import 'PartyCodeScreen.dart'; // Import the PartyCodeViewModel

class Step1Screen extends StatelessWidget {
  final String name; // Name passed from previous screen

  const Step1Screen({super.key, required this.name}); // Constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Greeting text with party name
            Align(
              alignment: Alignment.center, // Adjusted alignment
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                margin: const EdgeInsets.only(left: 16), // Moved left
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Let’s get this party started with $name!',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Genie image
            Image.asset(
              'assets/images/genie.png',
              height: 400,
              width: 400,
            ),
            const SizedBox(height: 24),

            // "Continue" button with navigation
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PartyCodeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[500],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                minimumSize: const Size(140, 50),
              ),
              child: const Text(
                'CONTINUE',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
