import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// PaymentService — handles the full Stripe Payment Sheet flow.
///
/// Architecture:
///   Flutter App → Firebase Cloud Function (createPaymentIntent)
///               → Stripe API → returns clientSecret
///               → Flutter presents Stripe Payment Sheet
///               → User enters card details (handled by Stripe, PCI compliant)
///               → Result returned to Flutter
///
/// The Stripe SECRET key is NEVER in this file. It lives in Firebase Cloud
/// Functions. Only the publishable key (set in main.dart) is on the client.
class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  /// Creates a Stripe PaymentIntent via Firebase Cloud Function.
  /// Returns the clientSecret needed to confirm the payment.
  ///
  /// [amount] — total in LKR (e.g. 1500.00)
  /// [currency] — ISO 4217 code, defaults to 'lkr'
  ///
  /// Returns a Map with 'clientSecret' and 'paymentIntentId'.
  Future<Map<String, String>> createPaymentIntent(
    double amount, {
    String currency = 'lkr',
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call({
        'amount': amount,
        'currency': currency,
      });

      final data = result.data as Map<dynamic, dynamic>;
      return {
        'clientSecret': data['clientSecret'] as String,
        'paymentIntentId': data['paymentIntentId'] as String,
      };
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function error [${e.code}]: ${e.message}');
      throw _mapFunctionError(e);
    } catch (e) {
      debugPrint('createPaymentIntent error: $e');
      throw Exception('Failed to initialize payment. Please try again.');
    }
  }

  /// Initializes and presents the Stripe Payment Sheet to the user.
  ///
  /// [clientSecret] — obtained from [createPaymentIntent]
  /// [customerEmail] — pre-fills the email in the payment sheet
  Future<void> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail,
  }) async {
    try {
      // Initialize the Payment Sheet with styling and config
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Furniq',
          // Billing details collected automatically
          billingDetails: BillingDetails(
            email: customerEmail,
          ),
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
            email: CollectionMode.always,
            name: CollectionMode.always,
          ),
          // Style
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFF6B4423), // Furniq brand brown
            ),
            shapes: const PaymentSheetShape(
              borderRadius: 12,
            ),
            primaryButton: const PaymentSheetPrimaryButtonAppearance(
              shapes: PaymentSheetPrimaryButtonShape(blurRadius: 8),
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF6B4423),
                  text: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );

      // Present the Payment Sheet — user enters card details here
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      debugPrint('Stripe exception: ${e.error.code} — ${e.error.message}');
      throw _mapStripeError(e);
    } catch (e) {
      debugPrint('presentPaymentSheet error: $e');
      rethrow;
    }
  }

  /// Full payment flow:
  /// 1. Creates a PaymentIntent via Cloud Function
  /// 2. Presents the Stripe Payment Sheet
  ///
  /// Returns the Stripe PaymentIntent ID on success.
  /// Throws an exception with a user-friendly message on failure.
  ///
  /// [amount] — total in LKR
  /// [customerEmail] — user's email
  Future<String> processPayment({
    required double amount,
    required String customerEmail,
  }) async {
    // Step 1: Create PaymentIntent
    final intentData = await createPaymentIntent(amount, currency: 'lkr');
    final clientSecret = intentData['clientSecret']!;
    final paymentIntentId = intentData['paymentIntentId']!;

    // Step 2: Present Payment Sheet (user fills card details)
    await presentPaymentSheet(
      clientSecret: clientSecret,
      customerEmail: customerEmail,
    );

    // If we reach here, payment was confirmed successfully
    return paymentIntentId;
  }

  // ──────────────────────────────────────────────────────────
  // Error Mappers
  // ──────────────────────────────────────────────────────────

  Exception _mapFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return Exception('Please sign in to make a payment.');
      case 'invalid-argument':
        return Exception('Invalid payment details: ${e.message}');
      case 'failed-precondition':
        return Exception('Card error: ${e.message}');
      case 'internal':
        return Exception('Payment server error: ${e.message}');
      default:
        return Exception(e.message ?? 'Payment failed. Please try again.');
    }
  }

  Exception _mapStripeError(StripeException e) {
    switch (e.error.code) {
      case FailureCode.Canceled:
        return Exception('Payment was cancelled.');
      case FailureCode.Failed:
        return Exception(
          e.error.message ?? 'Payment failed. Please check your card details.',
        );
      case FailureCode.Timeout:
        return Exception('Payment timed out. Please try again.');
      default:
        return Exception(
          e.error.message ?? 'An unexpected payment error occurred.',
        );
    }
  }
}
