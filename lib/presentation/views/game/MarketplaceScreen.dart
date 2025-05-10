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
  String? selectedFrame;
  String? selectedDecoration;
  String? selectedBackground;
  Map<String, bool> cosmeticBought = {};

  // Define cosmetic items with more appealing options
  final Map<String, Map<String, dynamic>> cosmeticItems = {
    // Premium frames
    'frame_rainbow': {
      'name': 'Rainbow Edge',
      'description': 'Animated rainbow border that cycles through colors',
      'price': 120,
      'icon': Icons.gradient,
      'category': 'Frames',
      'color': Colors.purpleAccent,
    },
    'frame_galaxy': {
      'name': 'Galaxy Frame',
      'description': 'A cosmic frame with shimmering stars',
      'price': 150,
      'icon': Icons.auto_awesome,
      'category': 'Frames',
      'color': Colors.indigo,
    },
    'frame_neon': {
      'name': 'Neon Pulse',
      'description': 'Electric neon frame that pulses with light',
      'price': 180,
      'icon': Icons.lightbulb_outline,
      'category': 'Frames',
      'color': Colors.greenAccent,
    },

    // Cool decorations
    'decoration_confetti': {
      'name': 'Party Confetti',
      'description': 'Celebratory confetti that bursts around your profile',
      'price': 100,
      'icon': Icons.celebration,
      'category': 'Decorations',
      'color': Colors.amber,
    },
    'decoration_flames': {
      'name': 'Flame Aura',
      'description': 'Animated fire effect around your avatar',
      'price': 150,
      'icon': Icons.local_fire_department,
      'category': 'Decorations',
      'color': Colors.deepOrange,
    },
    'decoration_bubbles': {
      'name': 'Floating Bubbles',
      'description': 'Dreamy bubbles that float around your profile',
      'price': 120,
      'icon': Icons.blur_circular,
      'category': 'Decorations',
      'color': Colors.lightBlueAccent,
    },

    // Stunning backgrounds
    'background_aurora': {
      'name': 'Northern Lights',
      'description': 'Mesmerizing aurora borealis effect',
      'price': 200,
      'icon': Icons.waves,
      'category': 'Backgrounds',
      'color': Colors.teal,
    },
    'background_cityscape': {
      'name': 'Neon Cityscape',
      'description': 'Futuristic city skyline with glowing lights',
      'price': 180,
      'icon': Icons.location_city,
      'category': 'Backgrounds',
      'color': Colors.blueGrey,
    },
    'background_space': {
      'name': 'Deep Space',
      'description': 'Breathtaking cosmic nebula with distant stars',
      'price': 220,
      'icon': Icons.nightlight_round,
      'category': 'Backgrounds',
      'color': Colors.deepPurple,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserIdAndCoins();
    _loadCatState();
    _loadEquippedItems();
    _loadCosmeticPurchaseState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCoins();
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      
      if (token == null) {
        print('No access token found for fetching coins');
        return;
      }

      final response = await http.get(
        Uri.parse('$backendUrl/user/$userId/coins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Fetching coins response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          coins = data['coins'] ?? 0;
        });
      } else {
        print('Failed to fetch coins: ${response.statusCode}');
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
      await _fetchCoins();
      setState(() {}); // Force UI update
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

  Future<void> _loadEquippedItems() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      catEquipped = prefs.getBool('catEquipped') ?? false;
      selectedFrame = prefs.getString('selectedFrame');
      selectedDecoration = prefs.getString('selectedDecoration');
      selectedBackground = prefs.getString('selectedBackground');
    });
  }

  Future<void> _saveEquippedItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('catEquipped', catEquipped);
    await prefs.setString('selectedFrame', selectedFrame ?? '');
    await prefs.setString('selectedDecoration', selectedDecoration ?? '');
    await prefs.setString('selectedBackground', selectedBackground ?? '');
  }

  Future<void> _loadCosmeticPurchaseState() async {
    final prefs = await SharedPreferences.getInstance();

    // Initialize all cosmetic items as not bought
    Map<String, bool> loadedCosmeticBought = {};
    for (var key in cosmeticItems.keys) {
      loadedCosmeticBought[key] = prefs.getBool('bought_$key') ?? false;
    }

    setState(() {
      cosmeticBought = loadedCosmeticBought;
    });
  }

  Future<void> _saveCosmeticPurchaseState() async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in cosmeticBought.entries) {
      await prefs.setBool('bought_${entry.key}', entry.value);
    }
  }

  Future<void> _buyCosmetic(String id, int price) async {
    if (userId == null || coins < price || cosmeticBought[id] == true) return;
    final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/user/$userId/add-coins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': -price}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          cosmeticBought[id] = true;
        });
        await _saveCosmeticPurchaseState();
        await _fetchCoins();

        // Show a fun animation or dialog for purchase success
        _showPurchaseSuccessDialog(id);
      }
    } catch (e) {
      print('Error buying cosmetic: $e');
    }
  }

  void _showPurchaseSuccessDialog(String id) {
    final itemName = cosmeticItems[id]?['name'] ?? 'item';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cosmeticItems[id]?['color'] ?? kPrimaryBlue,
            width: 3,
          ),
        ),
        title: Text('Awesome!',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold
            )
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cosmeticItems[id]?['icon'] ?? Icons.check_circle,
              size: 60,
              color: cosmeticItems[id]?['color'] ?? kPrimaryBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'You now own the $itemName!',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Nice!', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kPrimaryBlue.withOpacity(0.3), theme.scaffoldBackgroundColor],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader('Pets', Icons.pets),
                const SizedBox(height: 10),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/images/cat.gif', width: 40, height: 40),
                      ),
                      title: const Text('Cat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          const Text('50 coins', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      trailing: petBought
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                catEquipped = !catEquipped;
                              });
                              await _saveEquippedItems();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: catEquipped ? Colors.redAccent : kPrimaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(catEquipped ? 'Unequip' : 'Equip'),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: const Text(
                              'Owned',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                          : ElevatedButton(
                        onPressed: coins >= 50 && !petBought ? _buyCat : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Buy', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Games', Icons.gamepad),
                const SizedBox(height: 10),
                _buildGameItem(
                  'Hangman',
                  'Test your vocabulary in this classic word guessing game',
                  Icons.psychology,
                  Colors.orange,
                  100,
                  hangmanBought,
                  _buyHangman,
                ),
                _buildGameItem(
                  'Word Jumble',
                  'Unscramble letters to form words and improve your skills',
                  Icons.text_fields,
                  Colors.green,
                  100,
                  jumbleBought,
                  _buyJumble,
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Premium Profile Cosmetics', Icons.auto_awesome),
                const SizedBox(height: 15),

                // Group cosmetics by category
                ..._buildCosmeticsByCategory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Colors.white),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black26,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameItem(
      String name,
      String description,
      IconData icon,
      Color color,
      int price,
      bool isBought,
      Function() onBuy,
      ) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(description),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '$price coins',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          trailing: isBought
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: const Text(
              'Owned',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : ElevatedButton(
            onPressed: coins >= price && !isBought ? onBuy : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Buy', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCosmeticsByCategory() {
    // Group cosmetics by category
    Map<String, List<String>> categorizedCosmetics = {};

    cosmeticItems.forEach((id, item) {
      final category = item['category'] as String;
      if (!categorizedCosmetics.containsKey(category)) {
        categorizedCosmetics[category] = [];
      }
      categorizedCosmetics[category]!.add(id);
    });

    List<Widget> sections = [];

    // Build each category section
    categorizedCosmetics.forEach((category, itemIds) {
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 5),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: category == 'Frames' ? Colors.purpleAccent :
              category == 'Decorations' ? Colors.amber :
              Colors.teal,
              shadows: const [
                Shadow(
                  blurRadius: 3.0,
                  color: Colors.black26,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
        ),
      );

      for (var id in itemIds) {
        sections.add(_buildCosmeticItem(id));
      }

      sections.add(const SizedBox(height: 20));
    });

    return sections;
  }

  Widget _buildCosmeticItem(String id) {
    final item = cosmeticItems[id]!;
    final name = item['name'] as String;
    final description = item['description'] as String;
    final price = item['price'] as int;
    final icon = item['icon'] as IconData;
    final color = item['color'] as Color;

    final isBought = cosmeticBought[id] ?? false;
    final isSelected =
        (item['category'] == 'Frames' && selectedFrame == id) ||
            (item['category'] == 'Decorations' && selectedDecoration == id) ||
            (item['category'] == 'Backgrounds' && selectedBackground == id);

    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(description),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '$price coins',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          trailing: isBought
              ? ElevatedButton(
            onPressed: () {
              setState(() {
                if (item['category'] == 'Frames') {
                  selectedFrame = isSelected ? null : id;
                } else if (item['category'] == 'Decorations') {
                  selectedDecoration = isSelected ? null : id;
                } else if (item['category'] == 'Backgrounds') {
                  selectedBackground = isSelected ? null : id;
                }
                _saveEquippedItems();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.redAccent : color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: isSelected ? 2 : 4,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              isSelected ? 'Unequip' : 'Equip',
              style: const TextStyle(fontSize: 16),
            ),
          )
              : ElevatedButton(
            onPressed: coins >= price ? () => _buyCosmetic(id, price) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Buy', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}