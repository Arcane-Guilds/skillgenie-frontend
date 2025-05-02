// payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'dart:async';
import 'dart:js_util' as js_util;

// JS interop annotations for Stripe web functions
@JS('stripeWebInit')
external bool stripeWebInit(String publishableKey);

@JS('showStripePaymentModal')
external Object showStripePaymentModal(String clientSecret, int amount);

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

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
    _initializeStripe();
  }

  void _checkConfiguration() {
    print('=================== PAYMENT CONFIGURATION ===================');
    print('API URL: $_backendUrl');
    print('Stripe Key Available: ${_publishableKey != null}');
    if (_publishableKey != null) {
      print('Stripe Key Preview: ${_publishableKey!.substring(0, 10)}...');
    }
    print('=========================================================');
  }

  Future<void> _initializeStripe() async {
    try {
      if (_publishableKey == null) {
        throw Exception('Stripe publishable key is not configured');
      }

      if (kIsWeb) {
        // Web initialization
        final result = stripeWebInit(_publishableKey!);
        print('Stripe initialization result: $result');
        if (result != true) {
          throw Exception('Failed to initialize Stripe on web');
        }
        setState(() {
          _stripeInitialized = true;
        });
        print('✅ Stripe initialized successfully for web');
      } else {
        // Mobile initialization
        Stripe.publishableKey = _publishableKey!;
        await Stripe.instance.applySettings();
        setState(() {
          _stripeInitialized = true;
        });
        print('✅ Stripe initialized successfully for mobile');
      }
    } catch (e) {
      print('❌ Error initializing Stripe: $e');
      // Show error in UI
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
      if (kIsWeb) {
        // Web-specific payment flow using modal
        print('Starting web payment flow');

        // Calculate the amount in cents (integer)
        final amountCents = (widget.price * 100).toInt();

        // Show the Stripe payment modal and wait for result
        final paymentPromise = showStripePaymentModal(clientSecret, amountCents);
        print('Payment modal opened, awaiting result...');

        final result = await js_util.promiseToFuture(paymentPromise);
        print('Payment result: $result');

        final bool success = js_util.getProperty(result, 'success');
        if (success) {
          print('Web payment successful!');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, widget.coins);
        } else {
          final error = js_util.hasProperty(result, 'error')
              ? js_util.getProperty(result, 'error')
              : 'Payment failed';
          throw error;
        }
      } else {
        // Mobile payment flow
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            merchantDisplayName: 'SkillGenie',
            paymentIntentClientSecret: clientSecret,
          ),
        );
        await Stripe.instance.presentPaymentSheet();
        print('Mobile payment successful!');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, widget.coins);
      }
    } catch (e) {
      if (!mounted) return;
      print('ERROR OCCURRED:');
      print(e);
      String errorMessage = 'Payment failed';
      if (e is StripeException) {
        errorMessage = e.error.localizedMessage ?? e.error.message ?? 'Payment failed';
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
            if (kIsWeb)
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
                    const SizedBox(height: 16),
                    const Text(
                      'You will be prompted to enter your card details securely via Stripe after clicking the button below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Test card info box
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Test Mode Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This is a test mode integration. Use the following test card information:',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text('• Card Number: 4242 4242 4242 4242'),
                    Text('• Expiry Date: Any future date (MM/YY)'),
                    Text('• CVC: Any 3 digits'),
                    Text('• ZIP: Any 5 digits'),
                  ],
                ),
              ),
            // Pay button
            ElevatedButton(
              onPressed: (_stripeInitialized || !kIsWeb) && !_loading ? _handlePayment : null,
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