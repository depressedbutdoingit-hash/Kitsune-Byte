import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class BuildScreen extends StatefulWidget {
  const BuildScreen({super.key});

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  String _selectedTarget = 'Kitsuné Cloud';
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: KitsuneTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Build & Deploy',
          style: TextStyle(
            color: KitsuneTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Build Progress'),
            ..._buildSteps.map((step) => _buildStepItem(step)),
            const SizedBox(height: 24),
            _buildSectionTitle('Deploy Target'),
            _buildTargetCard('Kitsuné Cloud', 'Auto-scaling, SSL, backups included', Icons.cloud, true),
            _buildTargetCard('Custom VPS', 'Bring your own server', Icons.computer, false),
            _buildTargetCard('Static Export', 'HTML/CSS/JS only', Icons.code, false),
            const SizedBox(height: 24),
            _buildSectionTitle('Environment'),
            Row(
              children: [
                _buildEnvChip('Production', _selectedEnvironment == 'Production'),
                _buildEnvChip('Staging', _selectedEnvironment == 'Staging'),
                _buildEnvChip('Preview', _selectedEnvironment == 'Preview'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Domain'),
            TextField(
              style: const TextStyle(color: KitsuneTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'myapp',
                hintStyle: const TextStyle(color: KitsuneTheme.textTertiary),
                suffixText: '.kitsune.io',
                suffixStyle: const TextStyle(color: KitsuneTheme.textSecondary),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: KitsuneTheme.kitsuneOrange,
                ),
                const Text('Enable SSL (Let\'s Encrypt)', style: TextStyle(color: KitsuneTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Deploy Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KitsuneTheme.kitsuneTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: KitsuneTheme.textSecondary,
                  side: const BorderSide(color: KitsuneTheme.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save as Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(Map<String, dynamic> step) {
    final status = step['status'] as String;
    IconData icon;
    Color color;

    switch (status) {
      case 'success':
        icon = Icons.check_circle;
        color = KitsuneTheme.kitsuneTeal;
        break;
      case 'running':
        icon = Icons.sync;
        color = KitsuneTheme.kitsuneOrange;
        break;
      case 'failed':
        icon = Icons.error;
        color = KitsuneTheme.error;
        break;
      default:
        icon = Icons.circle_outlined;
        color = KitsuneTheme.textTertiary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step['name'],
              style: TextStyle(
                color: status == 'pending' ? KitsuneTheme.textTertiary : KitsuneTheme.textSecondary,
              ),
            ),
          ),
          if (step['time'] != null)
            Text(
              step['time'],
              style: const TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(String title, String subtitle, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? KitsuneTheme.kitsuneTeal.withOpacity(0.05) : KitsuneTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? KitsuneTheme.kitsuneTeal.withOpacity(0.3) : KitsuneTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? KitsuneTheme.kitsuneTeal : KitsuneTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? KitsuneTheme.textPrimary : KitsuneTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: KitsuneTheme.kitsuneTeal, size: 20),
        ],
      ),
    );
  }

  Widget _buildEnvChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedEnvironment = label),
        selectedColor: KitsuneTheme.kitsuneTeal.withOpacity(0.1),
        backgroundColor: KitsuneTheme.surface,
        labelStyle: TextStyle(
          color: isSelected ? KitsuneTheme.kitsuneTeal : KitsuneTheme.textSecondary,
        ),
        side: BorderSide(
          color: isSelected ? KitsuneTheme.kitsuneTeal.withOpacity(0.3) : KitsuneTheme.border,
        ),
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
}
