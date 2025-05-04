// mobile_payment_handler.dart
// This file should be used only on mobile platforms

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'payment_handler.dart';

// Direct implementation of MobilePaymentHandler for mobile platforms
class MobilePaymentHandlerImpl implements MobilePaymentHandler {
  @override
  Future<void> initialize(String publishableKey) async {
    // Skip initialization on web platforms
    if (kIsWeb) {
      return;
    }

    try {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      print('Mobile Stripe initialized successfully');
    } catch (e) {
      print('Error initializing Stripe on mobile: $e');
      rethrow;
    }
  }

  @override
  Future<PaymentResult> handlePayment(String clientSecret) async {
    if (kIsWeb) {
      return PaymentResult(
        success: false,
        error: 'Mobile payment handler used on web platform',
      );
    }

    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SkillGenie',
        ),
      );

      // Present the payment sheet to the user
      await Stripe.instance.presentPaymentSheet();

      // If we got here without an exception, the payment was successful
      return PaymentResult(
        success: true,
        paymentIntentId: clientSecret.split('_secret_')[0],
      );
    } catch (e) {
      // Handle Stripe errors
      String errorMessage = 'Payment failed';

      if (e is StripeException) {
        errorMessage = '${e.error.localizedMessage}';
      } else {
        errorMessage = e.toString();
      }

      return PaymentResult(
        success: false,
        error: errorMessage,
      );
    }
  }
}