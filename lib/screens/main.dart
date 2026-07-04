 import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock data - replace with your actual state management
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

  final Map<String, bool> _showSecret = {};
  String? _copiedKey;

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
        title: const Text(
          'Settings',
          style: TextStyle(
            color: KitsuneTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
          _buildSectionTitle('Editor'),
          _buildSliderSetting('Font Size', 10, 24, 14),
          _buildDropdownSetting('Font Family', ['JetBrains Mono', 'Fira Code', 'SF Mono']),
          _buildToggleSetting('Word Wrap', true),
          _buildToggleSetting('Vim Mode', false),
          const SizedBox(height: 24),
          _buildSectionTitle('Terminal'),
          _buildDropdownSetting('Default Shell', ['bash', 'zsh', 'fish']),
          _buildSliderSetting('Font Size', 8, 20, 12),
          const SizedBox(height: 24),
          _buildSectionTitle('Appearance'),
          Row(
            children: [
              _buildColorOption(KitsuneTheme.background, true),
              _buildColorOption(const Color(0xFF1a1a2e), false),
              _buildColorOption(const Color(0xFF0f172a), false),
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
              _buildSectionTitle('API Keys'),
              ElevatedButton.icon(
                onPressed: () => _showAddKeyDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Key'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KitsuneTheme.kitsuneOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._apiKeys.map((key) => _buildApiKeyCard(key)),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard(Map<String, dynamic> key) {
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
              Text(
                key['name'],
                style: const TextStyle(
                  color: KitsuneTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KitsuneTheme.kitsuneTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  key['provider'],
                  style: const TextStyle(
                    color: KitsuneTheme.kitsuneTeal,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: KitsuneTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${key['prefix']}••••••••',
                    style: const TextStyle(
                      color: KitsuneTheme.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _copiedKey == key['name'] ? Icons.check : Icons.copy,
                  color: _copiedKey == key['name'] ? KitsuneTheme.kitsuneTeal : KitsuneTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _copiedKey = key['name']);
                  // Copy to clipboard
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copiedKey = null);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: KitsuneTheme.error, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last used ${key['lastUsed']}',
        final monetization = MonetizationEngine(
  stripeSecretKey: 'sk_test_...',      // NEVER expose this in production
  stripePublishableKey: 'pk_test_...',  // This one is safe to expose
);
    style: const TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12),
          ),
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
              _buildSectionTitle('Secrets'),
              ElevatedButton.icon(
                onPressed: () => _showAddSecretDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Secret'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KitsuneTheme.kitsuneOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._secrets.map((secret) => _buildSecretCard(secret)),
        ],
      ),
    );
  }

  Widget _buildSecretCard(Map<String, dynamic> secret) {
    final id = secret['name'];
    final isVisible = _showSecret[id] ?? false;

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
              Text(
                secret['name'],
                style: const TextStyle(
                  color: KitsuneTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: KitsuneTheme.textSecondary, size: 18),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: KitsuneTheme.error, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            secret['description'],
            style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: KitsuneTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isVisible ? 'postgresql://user:pass@localhost:5432/db' : '••••••••••••••••',
                    style: const TextStyle(
                      color: KitsuneTheme.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: KitsuneTheme.textSecondary,
                  size: 20,
                ),
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
          _buildSectionTitle('AI Model'),
          _buildDropdownSetting('Model', ['Auto (Recommended)', 'GPT-4o', 'Claude 3.5 Sonnet', 'Llama 3 70B']),
          _buildToggleSetting('Local LLM Mode', true),
          _buildTextFieldSetting('Local Endpoint', 'http://localhost:11434'),
          _buildSliderSetting('Temperature', 0, 2, 0.7),
          const SizedBox(height: 24),
          _buildSectionTitle('Swarm'),
          _buildToggleSetting('Auto-deploy on save', false),
          _buildToggleSetting('Continuous monitoring', true),
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
            decoration: BoxDecoration(
              color: KitsuneTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KitsuneTheme.border),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Plan',
                  style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pro',
                  style: TextStyle(
                    color: KitsuneTheme.kitsuneOrange,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '\$19/month, renews Aug 15',
                  style: TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Usage This Month'),
          _buildUsageBar('AI Requests', 3247, 10000, KitsuneTheme.kitsuneViolet),
          _buildUsageBar('Deployments', 12, 50, KitsuneTheme.kitsuneTeal),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: KitsuneTheme.kitsuneOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Manage Subscription'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: KitsuneTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildToggleSetting(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)),
          Switch(
            value: value,
            onChanged: (_) {},
            activeColor: KitsuneTheme.kitsuneTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String label, double min, double max, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: KitsuneTheme.kitsuneOrange,
            inactiveColor: KitsuneTheme.border,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: KitsuneTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KitsuneTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.first,
                isExpanded: true,
                dropdownColor: KitsuneTheme.surface,
                style: const TextStyle(color: KitsuneTheme.textPrimary),
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldSetting(String label, String placeholder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: KitsuneTheme.textPrimary),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: KitsuneTheme.textTertiary),
              filled: true,
              fillColor: KitsuneTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: KitsuneTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: KitsuneTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: KitsuneTheme.kitsuneViolet),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(String label, int used, int total, Color color) {
    final percentage = used / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: KitsuneTheme.textSecondary, fontSize: 14)),
              Text('$used / $total', style: const TextStyle(color: KitsuneTheme.textPrimary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: KitsuneTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? KitsuneTheme.kitsuneOrange : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _showAddKeyDialog() {
    // Implement add key dialog
  }

  void _showAddSecretDialog() {
    // Implement add secret dialog
  }
}
'/': (context) => const HomeScreen(),
'/about': (context) => const AboutScreen(),
'/pricing': (context) => const PricingScreen(),
'/settings': (context) => const SettingsScreen(),
'/build': (context) => const BuildScreen(),
'/terminal': (context) => const TerminalScreen(),
