// payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../../../data/models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'payment_handler.dart';
import 'web_payment_handler.dart';
import 'mobile_payment_handler.dart';

class PaymentScreen extends StatefulWidget {
  final int coins;
  final double price;
  const PaymentScreen({super.key, required this.coins, required this.price});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  bool _stripeInitialized = false;
  late final String _backendUrl = dotenv.env['API_BASE_URL'] ?? '';
  late final String? _publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  late final PaymentHandler _paymentHandler;

  @override
  void initState() {
    super.initState();
    // Create the appropriate handler implementation based on platform
    _paymentHandler = kIsWeb
        ? WebPaymentHandlerImpl()
        : MobilePaymentHandlerImpl();
    _checkConfiguration();
    _initializeStripe();
  }

  void _checkConfiguration() {
    print('=================== PAYMENT CONFIGURATION ===================');
    print('API URL: $_backendUrl');
    print('Stripe Key Available: ${_publishableKey != null}');
    if (_publishableKey != null && _publishableKey!.isNotEmpty) {
      print('Stripe Key Preview: ${_publishableKey!.substring(0, min(_publishableKey!.length, 10))}...');
    }
    print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('=========================================================');
  }

  int min(int a, int b) => a < b ? a : b;

  Future<void> _initializeStripe() async {
    try {
      if (_publishableKey == null || _publishableKey!.isEmpty) {
        throw Exception('Stripe publishable key is not configured');
      }

      await _paymentHandler.initialize(_publishableKey!);
      if (mounted) {
        setState(() {
          _stripeInitialized = true;
        });
      }
      print('✅ Stripe initialized successfully');
    } catch (e) {
      print('❌ Error initializing Stripe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize payment system: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

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

      print('1. Creating payment intent...');
      final response = await http.post(
        Uri.parse('$_backendUrl/payment/intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': (widget.price * 100).toInt(),
          'currency': 'usd',
        }),
      );

      print('2. Payment intent response:');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw 'Payment failed: ${responseData['message'] ?? 'Unknown error'}';
      }

      final clientSecret = responseData['clientSecret'] as String?;
      if (clientSecret == null) {
        throw 'Invalid response from server: Missing client secret';
      }

      print('3. Processing payment...');
      final result = await _paymentHandler.handlePayment(clientSecret);

      if (result.success) {
        print('Payment successful!');

        // Add coins to user's balance in backend
        final success = await User.updateCoins(userId, widget.coins);

        if (!success) {
          // Show error but don't throw exception - payment was successful
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful but there was an issue updating your coins. Please contact support.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
          // Still return success since payment was processed
          Navigator.pop(context, widget.coins);
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, widget.coins);
      } else {
        throw result.error ?? 'Payment failed';
      }
    } catch (e) {
      if (!mounted) return;
      print('ERROR OCCURRED:');
      print(e);
      String errorMessage = 'Payment failed';
      if (e is Exception) {
        errorMessage = e.toString();
      } else {
        errorMessage = e.toString();
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
            // Stripe status
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _stripeInitialized ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _stripeInitialized ? Colors.green : Colors.amber,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _stripeInitialized ? Icons.check_circle : Icons.info_outline,
                    color: _stripeInitialized ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _stripeInitialized
                          ? 'Payment system ready'
                          : 'Payment system is initializing...',
                      style: TextStyle(
                        color: _stripeInitialized ? Colors.green : Colors.amber.shade800,
                      ),
                    ),
                  ),
                  if (!_stripeInitialized)
                    TextButton(
                      onPressed: _initializeStripe,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
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
              onPressed: _stripeInitialized && !_loading ? _handlePayment : null,
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
            // Platform indicator (for debugging)
            const SizedBox(height: 24),
            Text(
              'Platform: ${kIsWeb ? 'Web' : 'Mobile'}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}