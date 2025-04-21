import 'dart:math';
import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/hangman/homegame_screen.dart';
import 'package:skillGenie/crosswordgame/search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
class GamesScreen extends StatefulWidget {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Dark mode toggle coming soon!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              );
              if (result != null && result is Map<String, bool>) {
                setState(() {
                  petEquipped = result['pet']!;
                  hatEquipped = result['hat']!;
                });
              }
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
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, double opacity, child) => Opacity(opacity: opacity, child: child),
                child: const Text(
                  "Welcome, Player!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, double opacity, child) => Opacity(opacity: opacity, child: child),
                child: const Text(
                  "Choose Your Puzzle",
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 40),
              if (petEquipped)
                SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      const Icon(Icons.pets, size: 80, color: Colors.white),
                      if (hatEquipped)
                        const Positioned(
                          top: 0,
                          child: FaIcon(FontAwesomeIcons.hatWizard, size: 30, color: Colors.yellow),
                        ),
                    ],
                  ),
                ),
              _buildGameButton(context, GamesScreen.gamesList[0]),
              const SizedBox(height: 20),
              _buildGameButton(context, GamesScreen.gamesList[1]),
              const SizedBox(height: 20),
              _buildGameButton(context, GamesScreen.gamesList[2]),
              const SizedBox(height: 20),
              _buildSurpriseButton(context),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () => _showExitDialog(context),
                      child: const Text("Exit", style: TextStyle(color: Colors.white70)),
                    ),
                    const Text("v1.0.0", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton(BuildContext context, Map<String, dynamic> game) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Opening ${game['title']}...")));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => game['page'] as Widget),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: game['color'] as Color,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
          ),
          child: Text(
            game['title'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          game['description'] as String,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSurpriseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final randomGame = GamesScreen.gamesList[Random().nextInt(GamesScreen.gamesList.length)];
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Surprise! Opening ${randomGame['title']}...")));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => randomGame['page'] as Widget),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 10,
      ),
      child: const Text(
        "Surprise Me!",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int coins = 100;
  bool petBought = false;
  bool hatBought = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                '\u{1FA99} $coins',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Pets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            _buildItem(
              name: 'Cute Cat',
              cost: 50,
              bought: petBought,
              leading: const Icon(Icons.pets, size: 40, color: Colors.white),
              onBuy: () {
                if (coins >= 50 && !petBought) {
                  setState(() {
                    coins -= 50;
                    petBought = true;
                  });
                }
              },
            ),
            const SizedBox(height: 30),
            const Text('Hats', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            _buildItem(
              name: 'Wizard Hat',
              cost: 30,
              bought: hatBought,
              leading: const FaIcon(FontAwesomeIcons.hatWizard, size: 40, color: Colors.yellow),
              onBuy: () {
                if (coins >= 30 && !hatBought) {
                  setState(() {
                    coins -= 30;
                    hatBought = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: (petBought || hatBought)
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, {'pet': petBought, 'hat': hatBought});
        },
        label: const Text('Equip'),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }

  Widget _buildItem({
    required String name,
    required int cost,
    required bool bought,
    required Widget leading,
    required VoidCallback onBuy,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: leading,
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('$cost coins'),
        trailing: bought
            ? const Text('Bought', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            : ElevatedButton(onPressed: onBuy, child: const Text('Buy')),
      ),
    );
  }
}
