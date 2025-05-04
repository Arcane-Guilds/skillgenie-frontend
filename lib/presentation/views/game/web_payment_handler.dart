// web_payment_handler.dart
// This file should only be imported on web platforms

// Import only on web platform to avoid compilation errors
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_util' as js_util;
import 'package:js/js.dart';
import 'payment_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// For web-specific implementation
// We need to avoid direct references to dart:html and js packages in this file
// to prevent compilation errors on mobile platforms

// Interface implementation - this is platform-safe
class WebPaymentHandlerImpl implements WebPaymentHandler {
  @override
  Future<void> initialize(String publishableKey) async {
    if (kIsWeb) {
      // Initialize Stripe.js with the publishable key
      stripeWebInit(publishableKey);
    } else {
      // On non-web platforms, just return a successful future
      // This code path should never be taken due to our conditional logic
      return Future.value();
    }
  }

  @override
  Future<PaymentResult> handlePayment(String clientSecret, {int amount = 99}) async {
    if (kIsWeb) {
      try {
        final jsResult = await js_util.promiseToFuture(js_util.callMethod(
          js_util.globalThis,
          'showStripePaymentModal',
          [clientSecret, amount],
        ));
        final rawResult = js_util.dartify(jsResult);
        final result = <String, dynamic>{};
        if (rawResult is Map) {
          rawResult.forEach((key, value) {
            if (key is String) {
              result[key] = value;
            }
          });
        }
        if (result.isNotEmpty && result['success'] == true) {
          return PaymentResult(success: true, paymentIntentId: result['paymentIntentId']);
        } else {
          return PaymentResult(success: false, error: result['error'] ?? 'Payment failed');
        }
      } catch (e) {
        return PaymentResult(success: false, error: e.toString());
      }
    } else {
      // On non-web platforms, return a failed result
      // This code path should never be taken due to our conditional logic
      return PaymentResult(
        success: false,
        error: 'Web payment handler used on non-web platform',
      );
    }
  }
}

@JS('stripeWebInit')
external bool stripeWebInit(String publishableKey);

@JS('showStripePaymentModal')
external dynamic showStripePaymentModal(String clientSecret, int amount);