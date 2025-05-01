import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'payment_screen.dart';

class BuyCoinsScreen extends StatelessWidget {
  const BuyCoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> coinPackages = [
      {'coins': 100, 'price': 0.99},
      {'coins': 500, 'price': 3.99},
      {'coins': 1200, 'price': 8.99},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Coins'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Coin Package',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),
            ...coinPackages.map((pkg) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade200, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, size: 40, color: Colors.amber),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${pkg['coins']} Coins",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\$${pkg['price']}",
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final success = await Navigator.push<int>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                coins: pkg['coins'],
                                price: pkg['price'],
                              ),
                            ),
                          );
                          if (success != null && success > 0) {
                            // Only update coins if payment is successful
                            Navigator.pop(context, success); // Pass coins back after successful payment
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment failed.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Buy', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.2, end: 0);
            }),
          ],
        ),
      ),
    );
  }
}
