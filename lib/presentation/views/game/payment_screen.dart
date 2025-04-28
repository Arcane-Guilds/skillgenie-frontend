import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final int coins;
  final double price;

  const PaymentScreen({super.key, required this.coins, required this.price});

  @override
  Widget build(BuildContext context) {
    TextEditingController cardNumberController = TextEditingController();
    TextEditingController expiryController = TextEditingController();
    TextEditingController cvvController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$coins Coins for \$$price',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: cardNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        String cardNumber = cardNumberController.text;
                        String expiry = expiryController.text;
                        String cvv = cvvController.text;

                        if (cardNumber.length == 16 && expiry.length == 5 && cvv.length == 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment Successful! Coins Added.')),
                          );
                          Navigator.pop(context, coins);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid payment details. Please try again.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Confirm Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
