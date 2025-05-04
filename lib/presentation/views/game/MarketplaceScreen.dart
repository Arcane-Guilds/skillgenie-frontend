import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../data/models/user_model.dart';
import 'buy_coins_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../home/home_screen.dart'; // Import for kPrimaryBlue

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int coins = 0;
  bool petBought = false;
  bool catEquipped = false;
  bool hatBought = false;
  bool hangmanBought = false;
  bool jumbleBought = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndCoins();
    _loadCatState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCoins(); // Refresh coins when screen becomes active
  }

  Future<void> _loadUserIdAndCoins() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("user");
    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      userId = user.id;
      await _fetchCoins();
    }
  }

  Future<void> _fetchCoins() async {
    if (userId == null) return;
    final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
    try {
      final response = await http.get(Uri.parse('$backendUrl/user/$userId/coins'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched coins data: $data'); // Debug log
        setState(() {
          coins = data['coins'] ?? 0;
        });
      } else {
        print('Failed to fetch coins. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching coins: $e');
    }
  }

  Future<void> _handleBuyCoins() async {
    final bought = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const BuyCoinsScreen()),
    );
    if (bought != null) {
      await _fetchCoins(); // Always refresh from backend after purchase
    }
  }

  Future<void> _loadCatState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      petBought = prefs.getBool('petBought') ?? false;
      catEquipped = prefs.getBool('catEquipped') ?? false;
      hangmanBought = prefs.getBool('hangmanBought') ?? false;
      jumbleBought = prefs.getBool('jumbleBought') ?? false;
    });
  }

  Future<void> _saveCatState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('petBought', petBought);
    await prefs.setBool('catEquipped', catEquipped);
    await prefs.setBool('hangmanBought', hangmanBought);
    await prefs.setBool('jumbleBought', jumbleBought);
  }

  Future<void> _buyCat() async {
    if (userId == null || coins < 50 || petBought) return;
    final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/user/$userId/add-coins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': -50}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          petBought = true;
        });
        await _saveCatState();
        await _fetchCoins();
      } else {
        print('Failed to deduct coins. Status code: \\${response.statusCode}');
        print('Response body: \\${response.body}');
      }
    } catch (e) {
      print('Error deducting coins: $e');
    }
  }

  Future<void> _buyHangman() async {
    if (userId == null || coins < 100 || hangmanBought) return;
    final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/user/$userId/add-coins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': -100}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          hangmanBought = true;
        });
        await _saveCatState();
        await _fetchCoins();
      }
    } catch (e) {
      print('Error buying Hangman: $e');
    }
  }

  Future<void> _buyJumble() async {
    if (userId == null || coins < 100 || jumbleBought) return;
    final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/user/$userId/add-coins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': -100}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          jumbleBought = true;
        });
        await _saveCatState();
        await _fetchCoins();
      }
    } catch (e) {
      print('Error buying Jumble: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, catEquipped);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marketplace'),
          backgroundColor: kPrimaryBlue,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, size: 28),
              onPressed: _handleBuyCoins,
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
        body: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kPrimaryBlue.withOpacity(0.2), theme.scaffoldBackgroundColor],
                ),
              ),
            ),
            // Main
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Pets',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Image.asset('assets/images/cat.gif', width: 40, height: 40),
                      title: const Text('Cat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: const Text('50 coins'),
                      trailing: petBought
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    setState(() {
                                      catEquipped = !catEquipped;
                                    });
                                    await _saveCatState();
                                  },
                                  child: Text(catEquipped ? 'Unequip' : 'Equip'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: catEquipped ? Colors.red : kPrimaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Bought', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: coins >= 50 && !petBought
                                  ? _buyCat
                                  : null,
                              child: const Text('Buy'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Games',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Icon(Icons.games, size: 40, color: Colors.orange),
                      title: const Text('Hangman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: const Text('100 coins'),
                      trailing: hangmanBought
                          ? const Text('Bought', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                          : ElevatedButton(
                              onPressed: coins >= 100 && !hangmanBought ? _buyHangman : null,
                              child: const Text('Buy'),
                            ),
                    ),
                  ),
                  Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Icon(Icons.text_fields, size: 40, color: Colors.green),
                      title: const Text('Word Jumble', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: const Text('100 coins'),
                      trailing: jumbleBought
                          ? const Text('Bought', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                          : ElevatedButton(
                              onPressed: coins >= 100 && !jumbleBought ? _buyJumble : null,
                              child: const Text('Buy'),
                            ),
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
