import 'dart:math';
import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/game_page.dart';
import 'package:skillGenie/presentation/views/hangman/homegame_screen.dart';
import 'package:skillGenie/crosswordgame/search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  static final List<Map<String, dynamic>> gamesList = [
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
      'page': const SearchRoute(),
    },
  ];

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  bool petEquipped = false;
  bool hatEquipped = false;
  bool hangmanBought = false;
  bool jumbleBought = false;

  @override
  void initState() {
    super.initState();
    _loadGameUnlocks();
  }

  Future<void> _loadGameUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hangmanBought = prefs.getBool('hangmanBought') ?? false;
      jumbleBought = prefs.getBool('jumbleBought') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: UiUtils.responsiveAppBar(
        title: 'Games',
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, color: AppTheme.textPrimaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Dark mode toggle coming soon!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.store, color: AppTheme.textPrimaryColor),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Game',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test your knowledge while having fun!',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (petEquipped)
                SizedBox(
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.pets, 
                        size: 60, 
                        color: AppTheme.textPrimaryColor
                      ),
                      if (hatEquipped)
                        const Positioned(
                          top: 0,
                          child: FaIcon(
                            FontAwesomeIcons.hatWizard, 
                            size: 24, 
                            color: Colors.yellow
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  children: [
                    ...GamesScreen.gamesList.map((game) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildGameCard(
                          context,
                          game['title'],
                          game['description'],
                          game['icon'],
                          game['color'],
                          game['page'],
                        ).animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.3, end: 0),
                      ),
                    ),
                    _buildSurpriseCard(context)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    Widget page,
  ) {
    bool isLocked = false;
    if (title == 'Hangman') isLocked = !hangmanBought;
    if (title == 'Word Jumble') isLocked = !jumbleBought;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isLocked
            ? null
            : () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Opening $title...")));
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => page),
                );
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
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              isLocked
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Locked',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurpriseCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Only pick from unlocked games
          final unlockedGames = [
            {'title': 'WikiCross', 'page': const SearchRoute()},
            if (hangmanBought) {'title': 'Hangman', 'page': HomeGameScreen()},
            if (jumbleBought) {'title': 'Word Jumble', 'page': const Game()},
          ];
          if (unlockedGames.isEmpty) return;
          final randomGame = unlockedGames[Random().nextInt(unlockedGames.length)];
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Surprise! Opening \\${randomGame['title']}...")));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => randomGame['page'] as Widget),
          );
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
                Colors.teal.withOpacity(0.1),
                Colors.teal.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.casino,
                  color: Colors.teal,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Surprise Me!",
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Try a random game for fun!",
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
            ],
          ),
        ),
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