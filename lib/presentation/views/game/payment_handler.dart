// payment_handler.dart
// Base abstract interfaces for payment handling

import 'package:flutter/foundation.dart' show kIsWeb;

/// Result class for payment operations
class PaymentResult {
  final bool success;
  final String? error;
  final String? paymentIntentId;

  PaymentResult({
    required this.success,
    this.error,
    this.paymentIntentId,
  });
}

/// Base interface for all payment handlers
abstract class PaymentHandler {
  Future<void> initialize(String publishableKey);
  Future<PaymentResult> handlePayment(String clientSecret);
}

/// Interface for web-specific payment handler
abstract class WebPaymentHandler implements PaymentHandler {
  @override
  Future<void> initialize(String publishableKey);

  @override
  Future<PaymentResult> handlePayment(String clientSecret);
}

/// Interface for mobile-specific payment handler
abstract class MobilePaymentHandler implements PaymentHandler {
  @override
  Future<void> initialize(String publishableKey);

  @override
  Future<PaymentResult> handlePayment(String clientSecret);
}