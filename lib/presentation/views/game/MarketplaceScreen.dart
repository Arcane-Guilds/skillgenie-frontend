import 'package:flutter/material.dart';
import 'buy_coins_screen.dart'; // <--- Make sure you import it

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int coins = 100;
  bool petBought = false;
  bool hatBought = false;
  String? equippedPetPath;

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
                '\u{1FA99} $coins', // coin emoji
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
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BuyCoinsScreen()),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Buy Coins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Pets',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildItem(
              name: 'Cute Cat',
              cost: 50,
              bought: petBought,
              imagePath: 'assets/images/cat_pet.png', // make sure this asset exists
              onBuy: () {
                if (coins >= 50 && !petBought) {
                  setState(() {
                    coins -= 50;
                    petBought = true;
                    equippedPetPath = 'assets/images/cat_pet.png';
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
              imagePath: 'assets/images/hat.png',
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
      floatingActionButton: equippedPetPath != null
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, equippedPetPath);
        },
        label: const Text('Equip Pet'),
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
    required String imagePath,
    required VoidCallback onBuy,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Image.asset(imagePath, height: 40),
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('$cost coins'),
        trailing: bought
            ? const Text(
          'Bought',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        )
            : ElevatedButton(
          onPressed: onBuy,
          child: const Text('Buy'),
        ),
      ),
    );
  }
}
