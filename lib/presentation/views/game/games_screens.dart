import 'dart:math';
import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/hangman/homegame_screen.dart';
import 'package:skillGenie/crosswordgame/search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import 'package:skillGenie/presentation/views/game/MarketplaceScreen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  static final gamesList = <Map<String, dynamic>>[
    {
      'title': 'Hangman',
      'description': 'Guess the programming term before the man is hanged!',
      'color': Colors.orange,
      'icon': Icons.games,
      'page': HomeGameScreen(),
    },
    {
      'title': 'Word Jumble',
      'description': 'Unscramble programming terms to test your knowledge!',
      'color': Colors.green,
      'icon': Icons.text_fields,
      'page': const Game(),
    },
    {
      'title': 'WikiCross',
      'description': 'Solve programming-related crossword puzzles!',
      'color': Colors.blue,
      'icon': Icons.grid_on,
      'page': SearchRoute(),
    },
  ];

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Exit")),
        ],
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opening ${game['title']}...")));
          Navigator.push(context, MaterialPageRoute(builder: (_) => game['page'] as Widget));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (game['color'] as Color).withOpacity(0.1),
                (game['color'] as Color).withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (game['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(game['icon'] as IconData, color: game['color'] as Color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game['title'] as String,
                      style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game['description'] as String,
                      style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondaryColor, size: 20),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildSurpriseCard() {
    final game = GamesScreen.gamesList[Random().nextInt(GamesScreen.gamesList.length)];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Surprise! Opening ${game['title']}...")));
          Navigator.push(context, MaterialPageRoute(builder: (_) => game['page'] as Widget));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal.withOpacity(0.1), Colors.teal.withOpacity(0.05)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.casino, color: Colors.teal, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Surprise Me!", style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Try a random game for fun!", style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondaryColor, size: 20),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Games', style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: AppTheme.textPrimaryColor),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dark mode toggle coming soon!"))),
          ),
          IconButton(
            icon: Icon(Icons.store, color: AppTheme.textPrimaryColor),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          AppTheme.backgroundColor,
          AppTheme.backgroundColor.withOpacity(0.8),
        ])),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a Game', style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Test your knowledge while having fun!', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ...GamesScreen.gamesList.map(_buildGameCard),
                    _buildSurpriseCard(),
                  ],
                ),
              ),
              Center(child: TextButton(onPressed: _showExitDialog, child: Text("Exit", style: TextStyle(color: AppTheme.textSecondaryColor)))),
            ],
          ),
        ),
      ),
    );
  }
}
