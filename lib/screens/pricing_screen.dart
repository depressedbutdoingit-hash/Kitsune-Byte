import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final List<Map<String, dynamic>> _tiers = [
    {
      'name': 'Free',
      'price': 0,
      'description': 'Explore and build small projects',
      'features': ['1 active project', 'Local development', 'Basic AI (cloud)', 'Community support'],
      'highlighted': false,
    },
    {
      'name': 'Creator',
      'price': 9,
      'description': 'For solo builders shipping side projects',
      'features': ['Unlimited projects', 'Visual builder', 'Basic AI swarm', 'KitsunéDB (local + sync)', 'Deploy to *.kitsune.io', 'Kitsuné Shell', 'Email support'],
      'highlighted': false,
    },
    {
      'name': 'Pro',
      'price': 19,
      'description': 'For serious developers and small teams',
      'features': ['Everything in Creator', 'Advanced AI swarm (5 agents)', 'Custom domains + SSL', 'VPS deployment', 'App Store submission agent', 'Priority AI models', 'Team collaboration (3 seats)', 'Priority support'],
      'highlighted': true,
    },
    {
      'name': 'Power',
      'price': 39,
      'description': 'For agencies and power users',
      'features': ['Everything in Pro', 'Heavy AI usage', 'Team features (10 seats)', 'White-label deployments', 'Dedicated support', 'API access', 'Custom integrations', 'SLA guarantee'],
      'highlighted': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.background,
      appBar: AppBar(
        backgroundColor: KitsuneTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KitsuneTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pricing',
          style: TextStyle(
            color: KitsuneTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay for Outcomes.',
                    style: TextStyle(
                      color: KitsuneTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Not Tokens.',
                    style: TextStyle(
                      color: KitsuneTheme.textSecondary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No surprise bills. No hidden fees. No token math. Just build, deploy, and ship.',
                    style: TextStyle(
                      color: KitsuneTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._tiers.map((tier) => _buildPricingCard(tier)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KitsuneTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KitsuneTheme.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'Need something custom?',
                    style: TextStyle(
                      color: KitsuneTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enterprise plans with dedicated infrastructure, custom SLAs, and white-label options.',
                    style: TextStyle(color: KitsuneTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KitsuneTheme.textSecondary,
                      side: const BorderSide(color: KitsuneTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Contact Sales'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Free tier available with 1 project and limited AI. No credit card required.',
                style: TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> tier) {
    final isHighlighted = tier['highlighted'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlighted ? KitsuneTheme.elevated : KitsuneTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? KitsuneTheme.kitsuneOrange.withOpacity(0.5) : KitsuneTheme.border,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: KitsuneTheme.kitsuneOrange.withOpacity(0.1), blurRadius: 20)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: KitsuneTheme.kitsuneOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Most Popular',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          Text(
            tier['name'],
            style: const TextStyle(
              color: KitsuneTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tier['description'],
            style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tier['price'] == 0 ? 'Free' : '\$${tier['price']}',
                style: const TextStyle(
                  color: KitsuneTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (tier['price'] > 0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6, left: 4),
                  child: Text('/month', style: TextStyle(color: KitsuneTheme.textSecondary)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...((tier['features'] as List<String>).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check, color: KitsuneTheme.kitsuneTeal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _initiateCheckout(tier['name']),
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlighted ? KitsuneTheme.kitsuneOrange : KitsuneTheme.surface,
                foregroundColor: isHighlighted ? Colors.white : KitsuneTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isHighlighted ? BorderSide.none : const BorderSide(color: KitsuneTheme.border),
                ),
              ),
              child: Text(tier['price'] == 0 ? 'Get Started' : 'Subscribe'),
            ),
          ),
        ],
      ),
    );
  }

  void _initiateCheckout(String planName) {
    // TODO: Integrate with Stripe SDK or your monetization_engine.dart
    // This would call your backend to create a Stripe Checkout Session
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirecting to Stripe checkout for $planName...'),
        backgroundColor: KitsuneTheme.kitsuneTeal,
      ),
    );
  }
}
