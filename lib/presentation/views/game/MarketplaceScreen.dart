import 'package:flutter/material.dart';
import 'buy_coins_screen.dart';

// Global state for coins and purchases
class MarketState {
  static int coins = 100;
  static bool petBought = false;
  static bool hatBought = false;
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  Widget build(BuildContext context) {
    final coins = MarketState.coins;
    final petBought = MarketState.petBought;
    final hatBought = MarketState.hatBought;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () async {
              final bought = await Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (_) => const BuyCoinsScreen()),
              );
              if (bought != null) {
                setState(() {
                  MarketState.coins += bought;
                });
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
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
            const Text(
              'Pets',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildItem(
              name: 'Cat',
              cost: 50,
              bought: petBought,
              leading: const Icon(Icons.pets, size: 40, color: Colors.white),
              onBuy: () {
                if (MarketState.coins >= 50 && !petBought) {
                  setState(() {
                    MarketState.coins -= 50;
                    MarketState.petBought = true;
                  });
                }
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Hats',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildItem(
              name: 'Wizard Hat',
              cost: 30,
              bought: hatBought,
              leading: const Icon(Icons.checkroom, size: 40, color: Colors.yellow),
              onBuy: () {
                if (MarketState.coins >= 30 && !hatBought) {
                  setState(() {
                    MarketState.coins -= 30;
                    MarketState.hatBought = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: (petBought || hatBought)
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, {
          'pet': MarketState.petBought,
          'hat': MarketState.hatBought,
        }),
        icon: const Icon(Icons.check),
        label: const Text('Equip'),
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
