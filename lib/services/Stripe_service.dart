import 'dart:convert';
import 'package:http/http.dart' as http;

class StripeService {
  static const String _baseUrl = 'https://api.stripe.com/v1';
  final String _secretKey;
  final String _publishableKey;

  StripeService({
    required String secretKey,
    required String publishableKey,
  })  : _secretKey = secretKey,
        _publishableKey = publishableKey;

  String get publishableKey => _publishableKey;

  // Price IDs for each tier
  static const Map<String, String> priceIds = {
    'creator': 'price_creator_monthly',
    'pro': 'price_pro_monthly',
    'power': 'price_power_monthly',
  };

  // Tier info for UI
  static const Map<String, Map<String, dynamic>> tierInfo = {
    'free': {'name': 'Free', 'price': 0, 'priceId': null},
    'creator': {'name': 'Creator', 'price': 9, 'priceId': 'price_creator_monthly'},
    'pro': {'name': 'Pro', 'price': 19, 'priceId': 'price_pro_monthly'},
    'power': {'name': 'Power', 'price': 39, 'priceId': 'price_power_monthly'},
  };

  // Create checkout session
  Future<Map<String, dynamic>> createCheckoutSession({
    required String priceId,
    required String customerEmail,
    required String userId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/checkout/sessions'),
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'mode': 'subscription',
        'payment_method_types[]': 'card',
        'line_items[0][price]': priceId,
        'line_items[0][quantity]': '1',
        'success_url': successUrl ?? 'https://kitsune.io/success?session_id={CHECKOUT_SESSION_ID}',
        'cancel_url': cancelUrl ?? 'https://kitsune.io/cancel',
        'customer_email': customerEmail,
        'metadata[userId]': userId,
        'subscription_data[trial_period_days]': '7',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed: ${response.body}');
    }
  }

  // Get subscription
  Future<Map<String, dynamic>> getSubscription(String subscriptionId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
      headers: {'Authorization': 'Bearer $_secretKey'},
    );
    return jsonDecode(response.body);
  }

  // Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
      headers: {'Authorization': 'Bearer $_secretKey'},
    );
    return jsonDecode(response.body);
  }

  // Create billing portal
  Future<Map<String, dynamic>> createPortalSession({
    required String customerId,
    required String returnUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/billing_portal/sessions'),
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'customer': customerId,
        'return_url': returnUrl,
      },
    );
    return jsonDecode(response.body);
  }
}
