import 'dart:math';
import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/hangman/homegame_screen.dart';
import 'package:skillGenie/crosswordgame/search.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  // List of game data used for the buttons and for random selection.
  static final List<Map<String, dynamic>> gamesList = [
    {
      'title': 'Hangman',
      'description': 'Guess the word letter by letter!',
      'color': Colors.orange,
      'page': HomeGameScreen(),
    },
    {
      'title': 'Word Jumble',
      'description': 'Unscramble the letters to form a word.',
      'color': Colors.green,
      'page': const Game(),
    },
    {
      'title': 'WikiCross',
      'description': 'Solve clues based on Wikipedia hints.',
      'color': Colors.red,
      'page': SearchRoute(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Games',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // For demo purposes, we simply show a SnackBar.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Dark mode toggle coming soon!")),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Animated welcome text
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, double opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: const Text(
                  "Welcome, Player!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, double opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: const Text(
                  "Choose Your Puzzle",
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 40),
              // Game buttons with descriptions
              _buildGameButton(
                context,
                gamesList[0]['title'],
                gamesList[0]['description'],
                gamesList[0]['color'],
                gamesList[0]['page'],
              ),
              const SizedBox(height: 20),
              _buildGameButton(
                context,
                gamesList[1]['title'],
                gamesList[1]['description'],
                gamesList[1]['color'],
                gamesList[1]['page'],
              ),
              const SizedBox(height: 20),
              _buildGameButton(
                context,
                gamesList[2]['title'],
                gamesList[2]['description'],
                gamesList[2]['color'],
                gamesList[2]['page'],
              ),
              const SizedBox(height: 20),
              // Surprise me button
              _buildSurpriseButton(context),
              const Spacer(),
              // Exit button and version info at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        _showExitDialog(context);
                      },
                      child: const Text(
                        "Exit",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const Text(
                      "v1.0.0",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a game button along with its description.
  Widget _buildGameButton(
      BuildContext context, String title, String description, Color color, Widget page) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Show a SnackBar toast message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Opening $title...")),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 10,
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  // Build the "Surprise Me!" button
  Widget _buildSurpriseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final randomGame = gamesList[Random().nextInt(gamesList.length)];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Surprise! Opening ${randomGame['title']}...")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => randomGame['page'] as Widget),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 10,
      ),
      child: const Text(
        "Surprise Me!",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  // Display an exit confirmation dialog.
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Exit App"),
          content: const Text("Are you sure you want to exit?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Closes the app. For a proper exit, you can use SystemNavigator.pop() if needed.
                Navigator.of(context).pop();
                // Uncomment the next line to close the app (if desired).
                // SystemNavigator.pop();
              },
              child: const Text("Exit"),
            ),
          ],
        );
      },
    );
  }
}
