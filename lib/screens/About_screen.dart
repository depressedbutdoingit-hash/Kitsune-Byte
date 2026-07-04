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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KitsuneTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            color: KitsuneTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // H1
            const Text(
              'Built for Builders.\nBy Builders.',
              style: TextStyle(
                color: KitsuneTheme.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Even Offline.',
              style: TextStyle(
                color: KitsuneTheme.textSecondary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'We believe everyone should be able to build software — not just those with expensive laptops, fast internet, and years of experience.',
              style: TextStyle(
                color: KitsuneTheme.textSecondary,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),

            // H2
            _buildH2('Our Mission'),
            const Text(
              'Democratize app development by removing every barrier that keeps people from building.',
              style: TextStyle(
                color: KitsuneTheme.textSecondary,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _buildMissionCard('Accessibility', 'Build from a phone in Tijuana or a tablet in Tokyo. If you have an idea, you should be able to ship it.', Icons.accessibility),
            _buildMissionCard('Resilience', 'Internet is a luxury, not a guarantee. Kitsuné Byte works offline because the best ideas don\'t wait for WiFi.', Icons.offline_bolt),
            _buildMissionCard('Ownership', 'Your code, your data, your deployments. No platform lock-in. Export everything, anytime, anywhere.', Icons.lock),

            const SizedBox(height: 48),
            _buildH2('What Makes Us Different'),
            const SizedBox(height: 16),
            _buildDifferentiator('Mobile-First, Not Mobile-After', 'Every feature is designed for a 6-inch touch screen first. Desktop is a companion, not the default.'),
            _buildDifferentiator('Offline is the Foundation', 'Work for days without internet. Local LLMs, SQLite database, WASM bundler. Cloud sync is an enhancement.'),
            _buildDifferentiator('No External Accounts', 'No GitHub. No Cloudflare. No Render. No Supabase. One login. One bill. One platform.'),
            _buildDifferentiator('AI as a Swarm', 'Five agents working in parallel, not one assistant you query. They monitor, suggest, fix, and deploy.'),
            _buildDifferentiator('Pay for Outcomes', 'You buy capabilities, not compute. No surprise bills. No token math. Just build, deploy, and ship.'),

            const SizedBox(height: 48),
            _buildH2('The Platform'),
            const SizedBox(height: 16),
            _buildFeatureRow(Icons.terminal, 'Kitsuné Shell', 'Full Linux terminal with package manager'),
            _buildFeatureRow(Icons.auto_awesome, 'AI Swarm', '5 specialized agents working in parallel'),
            _buildFeatureRow(Icons.database, 'KitsunéDB', 'Built-in backend with auth & storage'),
            _buildFeatureRow(Icons.cloud_upload, 'One-Tap Deploy', 'App + DB + Domain + SSL in 60 seconds'),
            _buildFeatureRow(Icons.mic, 'Voice Builder', 'Talk to build. Walk around and code.'),
            _buildFeatureRow(Icons.security, 'AI Project Doctor', 'Continuous monitoring & auto-fixes'),

            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Ready to Build Without Limits?',
                    style: TextStyle(
                      color: KitsuneTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Start Building Free'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KitsuneTheme.kitsuneOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Center(
              child: Text(
                '© 2026 Kitsuné Byte. All rights reserved.',
                style: TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildH2(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: KitsuneTheme.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMissionCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KitsuneTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KitsuneTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KitsuneTheme.kitsuneOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: KitsuneTheme.kitsuneOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: KitsuneTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: KitsuneTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferentiator(String title, String description) {
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
          Text(
            title,
            style: const TextStyle(
              color: KitsuneTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: KitsuneTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KitsuneTheme.kitsuneViolet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: KitsuneTheme.kitsuneViolet, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: KitsuneTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: KitsuneTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
