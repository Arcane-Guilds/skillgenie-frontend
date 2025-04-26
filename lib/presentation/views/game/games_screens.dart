import 'dart:math';
import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/hangman/homegame_screen.dart';
import 'package:skillGenie/crosswordgame/maincross.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

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
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  bool petEquipped = false;
  bool hatEquipped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Games'),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white,Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameButton(
                context,
                "Hangman",
                Colors.orange,
                 HomeGameScreen(),
              ),
              const SizedBox(height: 20),
              _buildGameButton(
                context,
                "Word Jumble",
                Colors.green,
                const Game(),
              ),
              const SizedBox(height: 20),
              _buildGameButton(
                context,
                "Wiki Crossword",
                Colors.red,
                const MainCrosswordScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton(BuildContext context, String title, Color color, Widget page) {
    return ElevatedButton(
      onPressed: () {
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
    );
  }
}
