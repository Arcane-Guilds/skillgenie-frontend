// payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../data/models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class PaymentScreen extends StatefulWidget {
  final int coins;
  final double price;
  const PaymentScreen({super.key, required this.coins, required this.price});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  final _backendUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<void> _handlePayment() async {
    print('=================== PAYMENT STARTED ===================');

    if (_backendUrl.isEmpty) {
      const message = 'Error: API URL not configured';
      print('ERROR: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Get the current user ID from auth state
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (!authViewModel.isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final userId = authViewModel.userId;
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Convert price to cents for Stripe
      final amountInCents = (widget.price * 100).toInt();

      print('1. Creating checkout session...');
      final response = await http.post(
        Uri.parse('$_backendUrl/payment/create-checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authViewModel.token}',
        },
        body: json.encode({
          'amount': amountInCents,
          'coins': widget.coins,
        }),
      );

      print('2. Checkout session response:');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to create checkout session');
      }

      final sessionData = json.decode(response.body);
      final checkoutUrl = sessionData['checkoutUrl'] as String;
      final sessionId = sessionData['sessionId'] as String;

      // Launch the checkout URL
      if (await canLaunch(checkoutUrl)) {
        await launch(
          checkoutUrl,
          forceSafariVC: false,
          forceWebView: false,
        );

        // Wait longer for the webhook to process
        print('Waiting 10 seconds for initial webhook processing...');
        await Future.delayed(const Duration(seconds: 10));

        // Verify payment status with retries
        bool verificationSuccess = false;
        int maxRetries = 8;  // Increased from 5 to 8
        int retryCount = 0;
        
        while (!verificationSuccess && retryCount < maxRetries) {
          try {
            print('Verification attempt ${retryCount + 1} of $maxRetries...');
            final verifyResponse = await http.get(
              Uri.parse('$_backendUrl/payment/session?sessionId=$sessionId'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${authViewModel.token}',
              },
            );

            if (verifyResponse.statusCode != 200) {
              print('Verification request failed with status code: ${verifyResponse.statusCode}');
              throw Exception('Failed to verify payment');
            }

            final verifyData = json.decode(verifyResponse.body);
            print('Verification response (attempt ${retryCount + 1}): $verifyData');
            
            // Check if the payment was successful by looking at the payment status
            if (verifyData['paymentStatus'] == 'paid') {
              verificationSuccess = true;
              print('Payment verified successfully through session status!');
              break;
            }
            
            print('Payment not verified yet. Status: ${verifyData['status']}, Payment Status: ${verifyData['paymentStatus']}');
            retryCount++;
            if (retryCount < maxRetries) {
              print('Waiting 5 seconds before next verification attempt...');
              await Future.delayed(const Duration(seconds: 5));
            }
          } catch (error) {
            print('Verification attempt ${retryCount + 1} failed with error: $error');
            retryCount++;
            if (retryCount < maxRetries) {
              print('Waiting 5 seconds before next verification attempt...');
              await Future.delayed(const Duration(seconds: 5));
            }
          }
        }

        // If verification failed, check user's balance
        if (!verificationSuccess) {
          print('Session verification failed, checking user balance...');
          try {
            final userResponse = await http.get(
              Uri.parse('$_backendUrl/user/$userId/coins'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${authViewModel.token}',
              },
            );

            if (userResponse.statusCode == 200) {
              final userData = json.decode(userResponse.body);
              final currentCoins = userData['coins'] as int;
              print('Current user coins: $currentCoins, Expected coins: ${widget.coins}');
              
              if (currentCoins >= widget.coins) {
                verificationSuccess = true;
                print('Payment verified through coin balance!');
              } else {
                print('Coin balance verification failed. Current balance is less than expected.');
              }
            } else {
              print('Failed to get user data. Status code: ${userResponse.statusCode}');
            }
          } catch (error) {
            print('Error checking user balance: $error');
          }
        }

        // Handle the final result
        if (!mounted) return;
        
        if (verificationSuccess) {
          // Refresh user data to get updated coin balance
          try {
            print('Refreshing user data to get final coin balance...');
            final userResponse = await http.get(
              Uri.parse('$_backendUrl/user/$userId/coins'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${authViewModel.token}',
              },
            );

            if (userResponse.statusCode == 200) {
              final userData = json.decode(userResponse.body);
              final currentCoins = userData['coins'] as int;
              print('Final coin balance: $currentCoins');
            } else {
              print('Failed to refresh user data. Status code: ${userResponse.statusCode}');
            }
          } catch (error) {
            print('Error refreshing user data: $error');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Your coins have been added.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.pop(context, widget.coins);
        } else {
          print('All verification attempts failed. Showing warning message...');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verification failed. Please check your account balance.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.pop(context, widget.coins);
        }
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } catch (error) {
      if (!mounted) return;
      print('ERROR OCCURRED:');
      print(error);
      String errorMessage = 'Payment failed';
      if (error is Exception) {
        errorMessage = error.toString();
      } else {
        errorMessage = error.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      print('=================== PAYMENT ENDED ===================');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment amount display
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Purchase ${widget.coins} Coins',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${widget.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pay button
            ElevatedButton(
              onPressed: !_loading ? _handlePayment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Pay \$${widget.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}