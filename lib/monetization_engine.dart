import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/stripe_service.dart';
import 'models/subscription.dart';

enum SubscriptionTier { free, creator, pro, power }

enum ModelTier { free, cheap, premium }

class MonetizationEngine {
  static final MonetizationEngine _instance = MonetizationEngine._internal();
  factory MonetizationEngine() => _instance;
  MonetizationEngine._internal();

  late final StripeService _stripe;
  Subscription? _currentSubscription;

  // Initialize with your Stripe keys
  void initialize({
    required String stripeSecretKey,
    required String stripePublishableKey,
  }) {
    _stripe = StripeService(
      secretKey: stripeSecretKey,
      publishableKey: stripePublishableKey,
    );
  }

  // ============== TIER CONFIGS (UPDATED PRICES) ==============

  static const Map<SubscriptionTier, TierConfig> tierConfigs = {
    SubscriptionTier.free: TierConfig(
      name: 'Free',
      monthlyPrice: 0,
      aiCreditsPerMonth: 500,
      allowedModelTiers: {ModelTier.free},
      maxActiveProjects: 1,
      maxDeploymentsPerMonth: 0,
      maxTeamSeats: 1,
      features: {'visual_builder', 'terminal', 'local_ai', 'basic_swarm', 'community_support'},
    ),
    SubscriptionTier.creator: TierConfig(
      name: 'Creator',
      monthlyPrice: 9,        // ← UPDATED from 5
      aiCreditsPerMonth: 5000,
      allowedModelTiers: {ModelTier.free, ModelTier.cheap},
      maxActiveProjects: -1,
      maxDeploymentsPerMonth: 3,
      maxTeamSeats: 1,
      features: {'visual_builder', 'terminal', 'local_ai', 'full_swarm', 'deployments', 'email_support'},
    ),
    SubscriptionTier.pro: TierConfig(
      name: 'Pro',
      monthlyPrice: 19,       // ← UPDATED from 15
      aiCreditsPerMonth: 20000,
      allowedModelTiers: {ModelTier.free, ModelTier.cheap, ModelTier.premium},
      maxActiveProjects: -1,
      maxDeploymentsPerMonth: 10,
      maxTeamSeats: 3,
      features: {
        'visual_builder', 'terminal', 'local_ai', 'full_swarm', 'deployments',
        'vps_deployment', 'app_store_agent', 'custom_agents', 'team_collab',
        'priority_support'
      },
    ),
    SubscriptionTier.power: TierConfig(
      name: 'Power',
      monthlyPrice: 39,       // ← UPDATED from 29
      aiCreditsPerMonth: 100000,
      allowedModelTiers: {ModelTier.free, ModelTier.cheap, ModelTier.premium},
      maxActiveProjects: -1,
      maxDeploymentsPerMonth: -1,
      maxTeamSeats: 10,
      features: {
        'visual_builder', 'terminal', 'local_ai', 'full_swarm', 'deployments',
        'vps_deployment', 'custom_vps', 'app_store_agent', 'custom_agents',
        'team_collab', 'priority_models', 'white_label', 'dedicated_support'
      },
    ),
  };

  // ============== CREDIT CONVERSION (INTERNAL TRACKING) ==============

  static double tokensToCredits(double dollarCost) => dollarCost * 1000;
  static double creditsToTokens(double credits) => credits / 1000;

  // ============== FEATURE PERMISSIONS ==============

  Future<UsageResult> canUseFeature({
    required String userId,
    required SubscriptionTier tier,
    required String feature,
    required ModelTier modelTier,
    double estimatedCreditCost = 0,
  }) async {
    final config = tierConfigs[tier]!;
    if (!config.features.contains(feature)) {
      return UsageResult.denied(
        'Upgrade to ${config.name} to use $feature',
        suggestion: 'upgrade',
      );
    }
    if (!config.allowedModelTiers.contains(modelTier)) {
      return UsageResult.denied(
        '${modelTier.toString()} models require higher plan',
        suggestion: 'upgrade',
      );
    }
    final remaining = await _getRemainingCredits(userId);
    if (remaining < estimatedCreditCost) {
      return UsageResult.denied(
        'Out of AI credits. ${remaining.toStringAsFixed(0)} remaining.',
        suggestion: 'upgrade_or_topup',
      );
    }
    return UsageResult.allowed(remainingCredits: remaining);
  }

  Future<void> deductCredits({
    required String userId,
    required double credits,
    required String feature,
    required String model,
  }) async {
    final current = await _getRemainingCredits(userId);
    await _setRemainingCredits(userId, current - credits);
  }

  final Map<String, double> _balances = {};

  Future<double> _getRemainingCredits(String userId) async {
    return _balances[userId] ??
        tierConfigs[SubscriptionTier.free]!.aiCreditsPerMonth.toDouble();
  }

  Future<void> _setRemainingCredits(String userId, double credits) async {
    _balances[userId] = credits;
  }

  // ============== STRIPE SUBSCRIPTION METHODS ==============

  Subscription? get currentSubscription => _currentSubscription;

  bool get isPro => _currentSubscription?.isPro ?? false;
  bool get isPower => _currentSubscription?.isPower ?? false;
  bool get canDeploy => isPro || isPower || (_currentSubscription?.tier == SubscriptionTier.creator);

  // Start checkout for a plan
  Future<String?> startCheckout({
    required String tier, // 'creator', 'pro', 'power'
    required String email,
    required String userId,
  }) async {
    try {
      final priceId = StripeService.priceIds[tier];
      if (priceId == null) return null;

      final session = await _stripe.createCheckoutSession(
        priceId: priceId,
        customerEmail: email,
        userId: userId,
      );

      // Return the checkout URL to open in browser
      return session['url'] as String?;
    } catch (e) {
      print('Checkout error: $e');
      return null;
    }
  }

  // Open billing portal to manage subscription
  Future<String?> openBillingPortal(String customerId) async {
    try {
      final session = await _stripe.createPortalSession(
        customerId: customerId,
        returnUrl: 'https://kitsune.io/settings',
      );
      return session['url'] as String?;
    } catch (e) {
      print('Portal error: $e');
      return null;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _stripe.cancelSubscription(subscriptionId);
      return true;
    } catch (e) {
      print('Cancel error: $e');
      return false;
    }
  }

  // Check if user has active subscription
  Future<bool> checkSubscription(String subscriptionId) async {
    try {
      final sub = await _stripe.getSubscription(subscriptionId);
      final status = sub['status'];
      return status == 'active' || status == 'trialing';
    } catch (e) {
      return false;
    }
  }

  // Get pricing info for UI
  Map<String, dynamic> getTierInfo(String tier) {
    return StripeService.tierInfo[tier] ?? {};
  }

  // All tiers for pricing page
  List<Map<String, dynamic>> get allTiers => [
    getTierInfo('free'),
    getTierInfo('creator'),
    getTierInfo('pro'),
    getTierInfo('power'),
  ];
}

// ============== SUPPORTING CLASSES ==============

class TierConfig {
  final String name;
  final int monthlyPrice;
  final int aiCreditsPerMonth;
  final Set<ModelTier> allowedModelTiers;
  final int maxActiveProjects;
  final int maxDeploymentsPerMonth;
  final int maxTeamSeats;
  final Set<String> features;

  const TierConfig({
    required this.name,
    required this.monthlyPrice,
    required this.aiCreditsPerMonth,
    required this.allowedModelTiers,
    required this.maxActiveProjects,
    required this.maxDeploymentsPerMonth,
    required this.maxTeamSeats,
    required this.features,
  });
}

class UsageResult {
  final bool allowed;
  final String? denialReason;
  final String? suggestion;
  final double? remainingCredits;

  UsageResult._({
    required this.allowed,
    this.denialReason,
    this.suggestion,
    this.remainingCredits,
  });

  factory UsageResult.allowed({double? remainingCredits}) =>
      UsageResult._(allowed: true, remainingCredits: remainingCredits);

  factory UsageResult.denied(String reason, {String? suggestion}) =>
      UsageResult._(allowed: false, denialReason: reason, suggestion: suggestion);
}
