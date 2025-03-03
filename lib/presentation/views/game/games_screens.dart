import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/hangman/homegame_screen.dart';
import 'package:skillGenie/crosswordgame/search.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

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
                "WikiCross",
                Colors.red,
                SearchRoute(),
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
