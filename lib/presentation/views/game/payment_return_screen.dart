import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PaymentReturnScreen extends StatefulWidget {
  final String? sessionId;
  final bool isSuccess;
  
  const PaymentReturnScreen({
    super.key,
    this.sessionId,
    this.isSuccess = true,
  });

  @override
  State<PaymentReturnScreen> createState() => _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends State<PaymentReturnScreen> {
  bool _verifying = true;
  bool _verified = false;
  String? _error;
  int _retryCount = 0;
  static const int maxRetries = 5;
  static const Duration retryDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    if (widget.isSuccess && widget.sessionId != null) {
      _verifyPayment();
    } else {
      _verifying = false;
    }
  }

  Future<void> _verifyPayment() async {
    try {
      final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
      print('Verifying payment for session: ${widget.sessionId}');
      print('Retry attempt: ${_retryCount + 1}');
      
      final response = await http.get(
        Uri.parse('$backendUrl/payment/session?sessionId=${widget.sessionId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['AUTH_TOKEN']}',
        },
      );

      print('Verification response status: ${response.statusCode}');
      print('Verification response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isComplete = data['status'] == 'complete' && data['paymentStatus'] == 'paid';
        
        print('Session status: ${data['status']}');
        print('Payment status: ${data['paymentStatus']}');
        
        if (isComplete) {
          setState(() {
            _verified = true;
            _verifying = false;
          });
        } else if (_retryCount < maxRetries) {
          // Retry after delay
          _retryCount++;
          print('Payment not complete yet, retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
          _verifyPayment();
        } else {
          setState(() {
            _verified = false;
            _verifying = false;
            _error = 'Payment verification failed - Please check your account balance';
          });
        }
      } else {
        setState(() {
          _verified = false;
          _verifying = false;
          _error = 'Failed to verify payment';
        });
      }
    } catch (e) {
      print('Error during payment verification: $e');
      setState(() {
        _verified = false;
        _verifying = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verifying) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying payment...'),
            ],
          ),
        ),
      );
    }

    final isSuccess = widget.isSuccess && _verified;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? 'Payment Successful!' : 'Payment Failed',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSuccess 
                ? 'Your coins have been added to your account.'
                : _error ?? 'There was an issue with your payment.',
              style: TextStyle(
                fontSize: 16,
                color: isSuccess ? Colors.grey : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/'); // Navigate to home screen
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }
} 