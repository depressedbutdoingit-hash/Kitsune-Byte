#!/bin/bash

# Kitsuné Byte - File Generator Script
# Run this in Termux: bash create_kitsune_files.sh

echo "Creating Kitsuné Byte file structure..."

# Create directories
mkdir -p lib/screens
mkdir -p lib/services
mkdir -p lib/models
mkdir -p lib/components

echo "Directories created."

# ============================================
# FILE 1: lib/models/subscription.dart
# ============================================
cat > lib/models/subscription.dart << 'EOF'
enum SubscriptionStatus {
  active,
  inactive,
  pastDue,
  canceled,
  trialing,
}

enum SubscriptionTier {
  free,
  creator,
  pro,
  power,
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionStatus status;
  final SubscriptionTier tier;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.status,
    required this.tier,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripePriceId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;
  bool get isPro => tier == SubscriptionTier.pro || tier == SubscriptionTier.power;
  bool get isPower => tier == SubscriptionTier.power;
}
EOF

echo "Created: lib/models/subscription.dart"

# ============================================
# FILE 2: lib/services/stripe_service.dart
# ============================================
cat > lib/services/stripe_service.dart << 'EOF'
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

  static const Map<String, String> priceIds = {
    'creator': 'price_creator_monthly',
    'pro': 'price_pro_monthly',
    'power': 'price_power_monthly',
  };

  static const Map<String, Map<String, dynamic>> tierInfo = {
    'free': {'name': 'Free', 'price': 0, 'priceId': null},
    'creator': {'name': 'Creator', 'price': 9, 'priceId': 'price_creator_monthly'},
    'pro': {'name': 'Pro', 'price': 19, 'priceId': 'price_pro_monthly'},
    'power': {'name': 'Power', 'price': 39, 'priceId': 'price_power_monthly'},
  };

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

  Future<Map<String, dynamic>> getSubscription(String subscriptionId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
      headers: {'Authorization': 'Bearer $_secretKey'},
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
      headers: {'Authorization': 'Bearer $_secretKey'},
    );
    return jsonDecode(response.body);
  }

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
EOF

echo "Created: lib/services/stripe_service.dart"

# ============================================
# FILE 3: lib/monetization_engine.dart (CLEAN)
# ============================================
cat > lib/monetization_engine.dart << 'EOF'
import 'dart:async';
import 'services/stripe_service.dart';
import 'models/subscription.dart';

enum SubscriptionTier { free, creator, pro, power }
enum ModelTier { free, cheap, premium }

class MonetizationEngine {
  static final MonetizationEngine _instance = MonetizationEngine._internal();
  factory MonetizationEngine() => _instance;
  MonetizationEngine._internal();

  StripeService? _stripe;
  Subscription? _currentSubscription;

  void initialize({
    required String stripeSecretKey,
    required String stripePublishableKey,
  }) {
    _stripe = StripeService(
      secretKey: stripeSecretKey,
      publishableKey: stripePublishableKey,
    );
  }

  static const Map<SubscriptionTier, TierConfig> tierConfigs = {
    SubscriptionTier.free: TierConfig(
      name: 'Free',
      monthlyPrice: 0,
      aiCreditsPerMonth: 500,
      allowedModelTiers: {ModelTier.free},
      maxActiveProjects: 1,
      maxDeploymentsPerMonth: 0,
      maxTeamSeats: 1,
      features: {'visual_builder', 'terminal', 'local_ai'},
    ),
    SubscriptionTier.creator: TierConfig(
      name: 'Creator',
      monthlyPrice: 9,
      aiCreditsPerMonth: 5000,
      allowedModelTiers: {ModelTier.free, ModelTier.cheap},
      maxActiveProjects: -1,
      maxDeploymentsPerMonth: 3,
      maxTeamSeats: 1,
      features: {'visual_builder', 'terminal', 'local_ai', 'deployments'},
    ),
    SubscriptionTier.pro: TierConfig(
      name: 'Pro',
      monthlyPrice: 19,
      aiCreditsPerMonth: 20000,
      allowedModelTiers: {ModelTier.free, ModelTier.cheap, ModelTier.premium},
      maxActiveProjects: -1,
      maxDeploymentsPerMonth: 10,
      maxTeamSeats: 3,
      features: {'visual_builder', 'terminal', 'local_ai', 'deployments', 'vps', 'app_store'},
    ),
    SubscriptionTier.power: TierConfig(
      name: 'Power',
      monthlyPrice: 39,
      aiCreditsPerMonth: 100000,
      allowedModelTiers: {ModelTier.free, ModelTier.cheap, ModelTier.premium},
      maxActiveProjects: -1,
      maxDeploymentsPerMonth: -1,
      maxTeamSeats: 10,
      features: {'everything'},
    ),
  };

  static double tokensToCredits(double dollarCost) => dollarCost * 1000;

  final Map<String, double> _balances = {};

  Future<double> getRemainingCredits(String userId) async {
    return _balances[userId] ?? tierConfigs[SubscriptionTier.free]!.aiCreditsPerMonth.toDouble();
  }

  Future<void> deductCredits(String userId, double credits) async {
    final current = await getRemainingCredits(userId);
    _balances[userId] = current - credits;
  }

  Future<bool> canUseFeature({
    required SubscriptionTier tier,
    required String feature,
    required ModelTier modelTier,
  }) async {
    final config = tierConfigs[tier]!;
    if (!config.features.contains(feature) && !config.features.contains('everything')) {
      return false;
    }
    if (!config.allowedModelTiers.contains(modelTier)) {
      return false;
    }
    return true;
  }

  Future<String?> startCheckout({
    required String tier,
    required String email,
    required String userId,
  }) async {
    if (_stripe == null) throw Exception('Stripe not initialized');
    final priceId = StripeService.priceIds[tier];
    if (priceId == null) return null;

    final session = await _stripe!.createCheckoutSession(
      priceId: priceId,
      customerEmail: email,
      userId: userId,
    );
    return session['url'] as String?;
  }

  Future<String?> openBillingPortal(String customerId) async {
    if (_stripe == null) throw Exception('Stripe not initialized');
    final session = await _stripe!.createPortalSession(
      customerId: customerId,
      returnUrl: 'https://kitsune.io/settings',
    );
    return session['url'] as String?;
  }

  Future<bool> cancelSubscription(String subscriptionId) async {
    if (_stripe == null) throw Exception('Stripe not initialized');
    try {
      await _stripe!.cancelSubscription(subscriptionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> get allTiers => [
    {'name': 'Free', 'price': 0, 'features': ['1 project', 'Basic AI']},
    {'name': 'Creator', 'price': 9, 'features': ['Unlimited projects', 'Deploy']},
    {'name': 'Pro', 'price': 19, 'features': ['VPS', 'App Store Agent']},
    {'name': 'Power', 'price': 39, 'features': ['Everything', '10 seats']},
  ];
}

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
EOF

echo "Created: lib/monetization_engine.dart"

# ============================================
# FILE 4: lib/screens/settings_screen.dart
# ============================================
cat > lib/screens/settings_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _showSecret = {};
  String? _copiedKey;

  final List<Map<String, dynamic>> _apiKeys = [
    {'name': 'OpenRouter Production', 'prefix': 'sk-or-v1-8f3a', 'provider': 'OpenRouter', 'lastUsed': '2h ago'},
    {'name': 'Stripe Webhook', 'prefix': 'whsec_9d2b', 'provider': 'Stripe', 'lastUsed': '1d ago'},
    {'name': 'Kitsuné Cloud', 'prefix': 'kb_live_7e4c', 'provider': 'Kitsuné', 'lastUsed': 'Just now'},
  ];

  final List<Map<String, dynamic>> _secrets = [
    {'name': 'DATABASE_URL', 'description': 'PostgreSQL connection string'},
    {'name': 'JWT_SECRET', 'description': 'Authentication token secret'},
    {'name': 'AWS_ACCESS_KEY', 'description': 'S3 storage credentials'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.background,
      appBar: AppBar(
        backgroundColor: KitsuneTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: KitsuneTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: KitsuneTheme.kitsuneOrange,
          labelColor: KitsuneTheme.kitsuneOrange,
          unselectedLabelColor: KitsuneTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'General'),
            Tab(icon: Icon(Icons.key), text: 'API Keys'),
            Tab(icon: Icon(Icons.lock), text: 'Secrets'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI'),
            Tab(icon: Icon(Icons.payment), text: 'Billing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildApiKeysTab(),
          _buildSecretsTab(),
          _buildAiTab(),
          _buildBillingTab(),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Editor'),
          _sliderSetting('Font Size', 10, 24, 14),
          _dropdownSetting('Font Family', ['JetBrains Mono', 'Fira Code', 'SF Mono']),
          _toggleSetting('Word Wrap', true),
          _toggleSetting('Vim Mode', false),
          const SizedBox(height: 24),
          _sectionTitle('Terminal'),
          _dropdownSetting('Default Shell', ['bash', 'zsh', 'fish']),
          _sliderSetting('Font Size', 8, 20, 12),
          const SizedBox(height: 24),
          _sectionTitle('Appearance'),
          Row(
            children: [
              _colorOption(KitsuneTheme.background, true),
              _colorOption(const Color(0xFF1a1a2e), false),
              _colorOption(const Color(0xFF0f172a), false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('API Keys'),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Key'),
                style: ElevatedButton.styleFrom(backgroundColor: KitsuneTheme.kitsuneOrange, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._apiKeys.map((key) => _apiKeyCard(key)),
        ],
      ),
    );
  }

  Widget _apiKeyCard(Map<String, dynamic> key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KitsuneTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KitsuneTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(key['name'], style: const TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: KitsuneTheme.kitsuneTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(key['provider'], style: const TextStyle(color: KitsuneTheme.kitsuneTeal, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: KitsuneTheme.background, borderRadius: BorderRadius.circular(8)),
                  child: Text('${key['prefix']}••••••••', style: const TextStyle(color: KitsuneTheme.textSecondary, fontFamily: 'monospace', fontSize: 13)),
                ),
              ),
              IconButton(
                icon: Icon(_copiedKey == key['name'] ? Icons.check : Icons.copy, color: _copiedKey == key['name'] ? KitsuneTheme.kitsuneTeal : KitsuneTheme.textSecondary, size: 20),
                onPressed: () {
                  setState(() => _copiedKey = key['name']);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copiedKey = null);
                  });
                },
              ),
              IconButton(icon: const Icon(Icons.delete, color: KitsuneTheme.error, size: 20), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 4),
          Text('Last used ${key['lastUsed']}', style: const TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSecretsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Secrets'),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Secret'),
                style: ElevatedButton.styleFrom(backgroundColor: KitsuneTheme.kitsuneOrange, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._secrets.map((secret) => _secretCard(secret)),
        ],
      ),
    );
  }

  Widget _secretCard(Map<String, dynamic> secret) {
    final id = secret['name'];
    final isVisible = _showSecret[id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: KitsuneTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: KitsuneTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(secret['name'], style: const TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: KitsuneTheme.textSecondary, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete, color: KitsuneTheme.error, size: 18), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(secret['description'], style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: KitsuneTheme.background, borderRadius: BorderRadius.circular(8)),
                  child: Text(isVisible ? 'postgresql://user:pass@localhost:5432/db' : '••••••••••••••••', style: const TextStyle(color: KitsuneTheme.textSecondary, fontFamily: 'monospace', fontSize: 13)),
                ),
              ),
              IconButton(
                icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: KitsuneTheme.textSecondary, size: 20),
                onPressed: () => setState(() => _showSecret[id] = !isVisible),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('AI Model'),
          _dropdownSetting('Model', ['Auto (Recommended)', 'GPT-4o', 'Claude 3.5 Sonnet', 'Llama 3 70B']),
          _toggleSetting('Local LLM Mode', true),
          _textFieldSetting('Local Endpoint', 'http://localhost:11434'),
          _sliderSetting('Temperature', 0, 2, 0.7),
          const SizedBox(height: 24),
          _sectionTitle('Swarm'),
          _toggleSetting('Auto-deploy on save', false),
          _toggleSetting('Continuous monitoring', true),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: KitsuneTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: KitsuneTheme.border)),
            child: const Column(
              children: [
                Text('Current Plan', style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14)),
                SizedBox(height: 8),
                Text('Pro', style: TextStyle(color: KitsuneTheme.kitsuneOrange, fontSize: 32, fontWeight: FontWeight.bold)),
                Text('\$19/month, renews Aug 15', style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Usage This Month'),
          _usageBar('AI Requests', 3247, 10000, KitsuneTheme.kitsuneViolet),
          _usageBar('Deployments', 12, 50, KitsuneTheme.kitsuneTeal),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: KitsuneTheme.kitsuneOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Manage Subscription'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)));
  Widget _toggleSetting(String label, bool value) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)), Switch(value: value, onChanged: (_) {}, activeColor: KitsuneTheme.kitsuneTeal)]));
  Widget _sliderSetting(String label, double min, double max, double value) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)), Slider(value: value, min: min, max: max, activeColor: KitsuneTheme.kitsuneOrange, inactiveColor: KitsuneTheme.border, onChanged: (_) {})]));
  Widget _dropdownSetting(String label, List<String> options) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: KitsuneTheme.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: KitsuneTheme.border)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: options.first, isExpanded: true, dropdownColor: KitsuneTheme.surface, style: const TextStyle(color: KitsuneTheme.textPrimary), items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(), onChanged: (_) {})))]));
  Widget _textFieldSetting(String label, String placeholder) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)), const SizedBox(height: 8), TextField(style: const TextStyle(color: KitsuneTheme.textPrimary), decoration: InputDecoration(hintText: placeholder, hintStyle: const TextStyle(color: KitsuneTheme.textTertiary), filled: true, fillColor: KitsuneTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KitsuneTheme.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KitsuneTheme.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KitsuneTheme.kitsuneViolet))))]));
  Widget _usageBar(String label, int used, int total, Color color) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14)), Text('$used / $total', style: const TextStyle(color: KitsuneTheme.textPrimary, fontSize: 14))]), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: used / total, backgroundColor: KitsuneTheme.background, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8))]));
  Widget _colorOption(Color color, bool isSelected) => Padding(padding: const EdgeInsets.only(right: 12), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? KitsuneTheme.kitsuneOrange : Colors.transparent, width: 2))));
}
EOF

echo "Created: lib/screens/settings_screen.dart"

# ============================================
# FILE 5: lib/screens/build_screen.dart
# ============================================
cat > lib/screens/build_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class BuildScreen extends StatefulWidget {
  const BuildScreen({super.key});

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  String _selectedEnvironment = 'Production';
  final List<Map<String, dynamic>> _buildSteps = [
    {'name': 'Install dependencies', 'status': 'success', 'time': '2.3s'},
    {'name': 'Lint & type check', 'status': 'success', 'time': '4.1s'},
    {'name': 'Build application', 'status': 'running', 'time': null},
    {'name': 'Optimize assets', 'status': 'pending', 'time': null},
    {'name': 'Deploy to Kitsuné Cloud', 'status': 'pending', 'time': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.background,
      appBar: AppBar(
        backgroundColor: KitsuneTheme.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: KitsuneTheme.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Build & Deploy', style: TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Build Progress'),
            ..._buildSteps.map((step) => _stepItem(step)),
            const SizedBox(height: 24),
            _sectionTitle('Deploy Target'),
            _targetCard('Kitsuné Cloud', 'Auto-scaling, SSL, backups included', Icons.cloud, true),
            _targetCard('Custom VPS', 'Bring your own server', Icons.computer, false),
            _targetCard('Static Export', 'HTML/CSS/JS only', Icons.code, false),
            const SizedBox(height: 24),
            _sectionTitle('Environment'),
            Row(children: [_envChip('Production'), _envChip('Staging'), _envChip('Preview')]),
            const SizedBox(height: 24),
            _sectionTitle('Domain'),
            TextField(style: const TextStyle(color: KitsuneTheme.textPrimary), decoration: InputDecoration(hintText: 'myapp', hintStyle: const TextStyle(color: KitsuneTheme.textTertiary), suffixText: '.kitsune.io', suffixStyle: const TextStyle(color: KitsuneTheme.textSecondary), filled: true, fillColor: KitsuneTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KitsuneTheme.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KitsuneTheme.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KitsuneTheme.kitsuneViolet)))),
            const SizedBox(height: 12),
            Row(children: [Checkbox(value: true, onChanged: (_) {}, activeColor: KitsuneTheme.kitsuneOrange), const Text('Enable SSL (Let\'s Encrypt)', style: TextStyle(color: KitsuneTheme.textSecondary))]),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.rocket_launch), label: const Text('Deploy Now'), style: ElevatedButton.styleFrom(backgroundColor: KitsuneTheme.kitsuneTeal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: KitsuneTheme.textSecondary, side: const BorderSide(color: KitsuneTheme.border), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Save as Draft'))),
          ],
        ),
      ),
    );
  }

  Widget _stepItem(Map<String, dynamic> step) {
    final status = step['status'] as String;
    IconData icon;
    Color color;
    switch (status) {
      case 'success': icon = Icons.check_circle; color = KitsuneTheme.kitsuneTeal; break;
      case 'running': icon = Icons.sync; color = KitsuneTheme.kitsuneOrange; break;
      case 'failed': icon = Icons.error; color = KitsuneTheme.error; break;
      default: icon = Icons.circle_outlined; color = KitsuneTheme.textTertiary;
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Expanded(child: Text(step['name'], style: TextStyle(color: status == 'pending' ? KitsuneTheme.textTertiary : KitsuneTheme.textSecondary))), if (step['time'] != null) Text(step['time'], style: const TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12))]));
  }

  Widget _targetCard(String title, String subtitle, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isSelected ? KitsuneTheme.kitsuneTeal.withOpacity(0.05) : KitsuneTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? KitsuneTheme.kitsuneTeal.withOpacity(0.3) : KitsuneTheme.border)),
      child: Row(children: [Icon(icon, color: isSelected ? KitsuneTheme.kitsuneTeal : KitsuneTheme.textSecondary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: isSelected ? KitsuneTheme.textPrimary : KitsuneTheme.textSecondary, fontWeight: FontWeight.w600)), Text(subtitle, style: const TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12))])), if (isSelected) const Icon(Icons.check_circle, color: KitsuneTheme.kitsuneTeal, size: 20)]),
    );
  }

  Widget _envChip(String label) {
    final isSelected = _selectedEnvironment == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedEnvironment = label),
        selectedColor: KitsuneTheme.kitsuneTeal.withOpacity(0.1),
        backgroundColor: KitsuneTheme.surface,
        labelStyle: TextStyle(color: isSelected ? KitsuneTheme.kitsuneTeal : KitsuneTheme.textSecondary),
        side: BorderSide(color: isSelected ? KitsuneTheme.kitsuneTeal.withOpacity(0.3) : KitsuneTheme.border),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)));
}
EOF

echo "Created: lib/screens/build_screen.dart"

# ============================================
# FILE 6: lib/screens/about_screen.dart
# ============================================
cat > lib/screens/about_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.background,
      appBar: AppBar(
        backgroundColor: KitsuneTheme.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: KitsuneTheme.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('About', style: TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Built for Builders.\nBy Builders.', style: TextStyle(color: KitsuneTheme.textPrimary, fontSize: 36, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 8),
            const Text('Even Offline.', style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 36, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 24),
            const Text('We believe everyone should be able to build software — not just those with expensive laptops, fast internet, and years of experience.', style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 16, height: 1.6)),
            const SizedBox(height: 48),
            _h2('Our Mission'),
            const Text('Democratize app development by removing every barrier that keeps people from building.', style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 16, height: 1.6)),
            const SizedBox(height: 24),
            _missionCard('Accessibility', 'Build from a phone in Tijuana or a tablet in Tokyo. If you have an idea, you should be able to ship it.', Icons.accessibility),
            _missionCard('Resilience', 'Internet is a luxury, not a guarantee. Kitsuné Byte works offline because the best ideas don\'t wait for WiFi.', Icons.offline_bolt),
            _missionCard('Ownership', 'Your code, your data, your deployments. No platform lock-in. Export everything, anytime, anywhere.', Icons.lock),
            const SizedBox(height: 48),
            _h2('What Makes Us Different'),
            _diffCard('Mobile-First, Not Mobile-After', 'Every feature is designed for a 6-inch touch screen first. Desktop is a companion, not the default.'),
            _diffCard('Offline is the Foundation', 'Work for days without internet. Local LLMs, SQLite database, WASM bundler. Cloud sync is an enhancement.'),
            _diffCard('No External Accounts', 'No GitHub. No Cloudflare. No Render. No Supabase. One login. One bill. One platform.'),
            _diffCard('AI as a Swarm', 'Five agents working in parallel, not one assistant you query. They monitor, suggest, fix, and deploy.'),
            _diffCard('Pay for Outcomes', 'You buy capabilities, not compute. No surprise bills. No token math. Just build, deploy, and ship.'),
            const SizedBox(height: 48),
            _h2('The Platform'),
            _featureRow(Icons.terminal, 'Kitsuné Shell', 'Full Linux terminal with package manager'),
            _featureRow(Icons.auto_awesome, 'AI Swarm', '5 specialized agents working in parallel'),
            _featureRow(Icons.database, 'KitsunéDB', 'Built-in backend with auth & storage'),
            _featureRow(Icons.cloud_upload, 'One-Tap Deploy', 'App + DB + Domain + SSL in 60 seconds'),
            _featureRow(Icons.mic, 'Voice Builder', 'Talk to build. Walk around and code.'),
            _featureRow(Icons.security, 'AI Project Doctor', 'Continuous monitoring & auto-fixes'),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  const Text('Ready to Build Without Limits?', style: TextStyle(color: KitsuneTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Start Building Free'),
                    style: ElevatedButton.styleFrom(backgroundColor: KitsuneTheme.kitsuneOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Center(child: Text('© 2026 Kitsuné Byte. All rights reserved.', style: TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _h2(String text) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(text, style: const TextStyle(color: KitsuneTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)));
  Widget _missionCard(String title, String desc, IconData icon) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: KitsuneTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: KitsuneTheme.border)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: KitsuneTheme.kitsuneOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: KitsuneTheme.kitsuneOrange, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(desc, style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 13, height: 1.5))]))]));
  Widget _diffCard(String title, String desc) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: KitsuneTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: KitsuneTheme.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 4), Text(desc, style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 13, height: 1.5))]));
  Widget _featureRow(IconData icon, String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: KitsuneTheme.kitsuneViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: KitsuneTheme.kitsuneViolet, size: 22)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.w600)), Text(subtitle, style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 13))]))]));
}
EOF

echo "Created: lib/screens/about_screen.dart"

# ============================================
# FILE 7: lib/screens/pricing_screen.dart
# ============================================
cat > lib/screens/pricing_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final List<Map<String, dynamic>> _tiers = [
    {'name': 'Free', 'price': 0, 'description': 'Explore and build small projects', 'features': ['1 active project', 'Local development', 'Basic AI (cloud)', 'Community support'], 'highlighted': false},
    {'name': 'Creator', 'price': 9, 'description': 'For solo builders shipping side projects', 'features': ['Unlimited projects', 'Visual builder', 'Basic AI swarm', 'KitsunéDB (local + sync)', 'Deploy to *.kitsune.io', 'Kitsuné Shell', 'Email support'], 'highlighted': false},
    {'name': 'Pro', 'price': 19, 'description': 'For serious developers and small teams', 'features': ['Everything in Creator', 'Advanced AI swarm (5 agents)', 'Custom domains + SSL', 'VPS deployment', 'App Store submission agent', 'Priority AI models', 'Team collaboration (3 seats)', 'Priority support'], 'highlighted': true},
    {'name': 'Power', 'price': 39, 'description': 'For agencies and power users', 'features': ['Everything in Pro', 'Heavy AI usage', 'Team features (10 seats)', 'White-label deployments', 'Dedicated support', 'API access', 'Custom integrations', 'SLA guarantee'], 'highlighted': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.background,
      appBar: AppBar(backgroundColor: KitsuneTheme.surface, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: KitsuneTheme.textPrimary), onPressed: () => Navigator.pop(context)), title: const Text('Pricing', style: TextStyle(color: KitsuneTheme.textPrimary, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pay for Outcomes.', style: TextStyle(color: KitsuneTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)), Text('Not Tokens.', style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 32, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('No surprise bills. No hidden fees. No token math. Just build, deploy, and ship.', style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 16))])),
            const SizedBox(height: 24),
            ..._tiers.map((tier) => _pricingCard(tier)),
            const SizedBox(height: 32),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: KitsuneTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: KitsuneTheme.border)), child: Column(children: [const Text('Need something custom?', style: TextStyle(color: KitsuneTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Enterprise plans with dedicated infrastructure, custom SLAs, and white-label options.', style: TextStyle(color: KitsuneTheme.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 16), OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: KitsuneTheme.textSecondary, side: const BorderSide(color: KitsuneTheme.border), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('Contact Sales'))])),
            const SizedBox(height: 32),
            const Center(child: Text('Free tier available with 1 project and limited AI. No credit card required.', style: TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _pricingCard(Map<String, dynamic> tier) {
    final isHighlighted = tier['highlighted'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isHighlighted ? KitsuneTheme.elevated : KitsuneTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isHighlighted ? KitsuneTheme.kitsuneOrange.withOpacity(0.5) : KitsuneTheme.border, width: isHighlighted ? 2 : 1), boxShadow: isHighlighted ? [BoxShadow(color: KitsuneTheme.kitsuneOrange.withOpacity(0.1), blurRadius: 20)] : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: KitsuneTheme.kitsuneOrange, borderRadius: BorderRadius.circular(20)), child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
          Text(tier['name'], style: const TextStyle(color: KitsuneTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(tier['description'], style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(tier['price'] == 0 ? 'Free' : '\$${tier['price']}', style: const TextStyle(color: KitsuneTheme.textPrimary, fontSize: 36, fontWeight: FontWeight.bold)), if (tier['price'] > 0) const Padding(padding: EdgeInsets.only(bottom: 6, left: 4), child: Text('/month', style: TextStyle(color: KitsuneTheme.textSecondary)))]),
          const SizedBox(height: 16),
          ...(tier['features'] as List<String>).map((feature) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check, color: KitsuneTheme.kitsuneTeal, size: 18), const SizedBox(width: 8), Expanded(child: Text(feature, style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14)))]))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: isHighlighted ? KitsuneTheme.kitsuneOrange : KitsuneTheme.surface, foregroundColor: isHighlighted ? Colors.white : KitsuneTheme.textPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: isHighlighted ? BorderSide.none : const BorderSide(color: KitsuneTheme.border))), child: Text(tier['price'] == 0 ? 'Get Started' : 'Subscribe'))),
        ],
      ),
    );
  }
}
EOF

echo "Created: lib/screens/pricing_screen.dart"

echo ""
echo "=========================================="
echo "All files created successfully!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - lib/models/subscription.dart"
echo "  - lib/services/stripe_service.dart"
echo "  - lib/monetization_engine.dart (cleaned)"
echo "  - lib/screens/settings_screen.dart"
echo "  - lib/screens/build_screen.dart"
echo "  - lib/screens/about_screen.dart"
echo "  - lib/screens/pricing_screen.dart"
echo ""
echo "Next steps:"
echo "  1. Add 'http: ^1.2.0' to your pubspec.yaml dependencies"
echo "  2. Run: flutter pub get"
echo "  3. Add routes in main.dart"
echo "  4. Run: flutter run"
# ============================================
# FILE 8: lib/screens/home_screen.dart
# ============================================
cat > lib/screens/home_screen.dart << 'EOF'
[PASTE HOME_SCREEN CODE HERE]
EOF

echo "Created: lib/screens/home_screen.dart"

# ============================================
# FILE 9: lib/screens/terminal_screen.dart
# ============================================
cat > lib/screens/terminal_screen.dart << 'EOF'
[PASTE TERMINAL_SCREEN CODE HERE]
EOF

echo "Created: lib/screens/terminal_screen.dart"
