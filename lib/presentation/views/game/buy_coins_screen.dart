import 'package:flutter/material.dart';
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
      ),
      body: ListView.builder(
        itemCount: coinPackages.length,
        itemBuilder: (context, index) {
          final package = coinPackages[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.amber),
              title: Text('${package['coins']} Coins'),
              subtitle: Text('\$${package['price']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        coins: package['coins'],
                        price: package['price'],
                      ),
                    ),
                  );
                },
                child: const Text('Buy'),
              ),
            ),
          );
        },
      ),
    );
  }
}
