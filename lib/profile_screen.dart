import 'package:flutter/material.dart';
import 'kitsune_theme_v3.dart';
import 'monetization_engine.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<<ProfileScreen> {
  SubscriptionTier _currentTier = SubscriptionTier.free;
  double _credits = 500;

  final List<TierDisplay> _tiers = [
    TierDisplay(tier: SubscriptionTier.free, name: 'Free', price: 0, color: KitsuneTheme.mistSilver, features: ['1 active project', '500 AI credits/mo', 'Free models only', 'Community support']),
    TierDisplay(tier: SubscriptionTier.creator, name: 'Creator', price: 5, color: KitsuneTheme.foxGlow, features: ['Unlimited projects', '5,000 AI credits/mo', 'Free + Cheap models', '3 deployments/mo', 'Email support']),
    TierDisplay(tier: SubscriptionTier.pro, name: 'Pro', price: 15, color: KitsuneTheme.foxOrange, features: ['Unlimited projects', '20,000 AI credits/mo', 'All models', '10 deployments/mo', 'VPS deployment', 'App Store agent', '3 team seats']),
    TierDisplay(tier: SubscriptionTier.power, name: 'Power', price: 29, color: KitsuneTheme.gold, features: ['Unlimited everything', '100,000 AI credits/mo', 'Priority models', 'Unlimited deploys', 'Custom VPS', '10 team seats', 'White label']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.deepCharcoal,
      appBar: AppBar(
        title: Text('Profile', style: KitsuneTheme.displayMedium()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: KitsuneTheme.foxGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: KitsuneTheme.deepCharcoal.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: KitsuneTheme.pearlOpal, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Developer', style: KitsuneTheme.displayMedium(color: KitsuneTheme.deepCharcoal)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: KitsuneTheme.deepCharcoal.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_currentTier.name.toUpperCase(), style: KitsuneTheme.label(color: KitsuneTheme.pearlOpal)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: KitsuneTheme.glassCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Credits', style: KitsuneTheme.displayMedium(fontSize: 18)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _credits / 5000,
                  backgroundColor: KitsuneTheme.shadowAuburn,
                  valueColor: AlwaysStoppedAnimation(_credits > 1000 ? KitsuneTheme.gold : KitsuneTheme.emberRed),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_credits.toInt()} remaining', style: KitsuneTheme.bodyLarge()),
                    TextButton(
                      onPressed: () {},
                      child: Text('Buy More', style: KitsuneTheme.bodyLarge(color: KitsuneTheme.foxOrange)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Choose Your Plan', style: KitsuneTheme.displayMedium()),
          const SizedBox(height: 16),
          ..._tiers.map((t) => _buildTierCard(t)),
          const SizedBox(height: 24),
          Text('Settings', style: KitsuneTheme.displayMedium()),
          const SizedBox(height: 16),
          _buildSettingTile(Icons.computer, 'Local AI', 'Ollama / LM Studio', () {}),
          _buildSettingTile(Icons.dark_mode, 'Theme', 'Dark (Iridescent Fox)', () {}),
          _buildSettingTile(Icons.notifications, 'Notifications', 'Enabled', () {}),
          _buildSettingTile(Icons.security, 'Security', 'Biometric lock', () {}),
          _buildSettingTile(Icons.logout, 'Sign Out', '', () {}),
        ],
      ),
    );
  }

  Widget _buildTierCard(TierDisplay tier) {
    final isCurrent = tier.tier == _currentTier;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrent ? tier.color.withOpacity(0.15) : KitsuneTheme.shadowAuburn.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrent ? tier.color : Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: () => setState(() => _currentTier = tier.tier),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: tier.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Text(tier.name, style: KitsuneTheme.displayMedium(fontSize: 20)),
                    ],
                  ),
                  Text(
                    tier.price == 0 ? 'FREE' : '\$${tier.price}/mo',
                    style: KitsuneTheme.displayMedium(fontSize: 18, color: tier.color),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...tier.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check, color: tier.color, size: 16),
                    const SizedBox(width: 8),
                    Text(f, style: KitsuneTheme.bodyLarge()),
                  ],
                ),
              )),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: tier.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: tier.color, size: 16),
                      const SizedBox(width: 8),
                      Text('Current Plan', style: KitsuneTheme.label(color: tier.color)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: KitsuneTheme.foxOrange),
      title: Text(title, style: KitsuneTheme.bodyLarge()),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: KitsuneTheme.label()) : null,
      trailing: const Icon(Icons.chevron_right, color: KitsuneTheme.mistSilver),
      onTap: onTap,
    );
  }
}

class TierDisplay {
  final SubscriptionTier tier;
  final String name;
  final int price;
  final Color color;
  final List<String> features;
  TierDisplay({required this.tier, required this.name, required this.price, required this.color, required this.features});
}
