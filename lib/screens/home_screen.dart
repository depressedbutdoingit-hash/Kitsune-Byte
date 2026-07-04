import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: KitsuneTheme.background.withOpacity(0.9),
            floating: true,
            title: _buildLogo(),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/about'),
                child: const Text('About', style: TextStyle(color: KitsuneTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/pricing'),
                child: const Text('Pricing', style: TextStyle(color: KitsuneTheme.textSecondary)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KitsuneTheme.kitsuneOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),

          // Hero Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Animated Fox Logo
                  _buildAnimatedFox(),
                  const SizedBox(height: 32),
                  // H1
                  const Text(
                    'Build Apps',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KitsuneTheme.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  // Gradient text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [KitsuneTheme.kitsuneOrange, KitsuneTheme.kitsuneViolet],
                    ).createShader(bounds),
                    child: const Text(
                      'Anywhere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const Text(
                    'Even Offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KitsuneTheme.textSecondary,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'The mobile-first, AI-native operating system for building apps. Terminal + Visual Builder + AI Swarm + Built-in Backend + One-Tap Deployment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KitsuneTheme.textSecondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text('Start Building Free'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KitsuneTheme.kitsuneOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/about'),
                        icon: const Icon(Icons.terminal),
                        label: const Text('See How It Works'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KitsuneTheme.textPrimary,
                          side: const BorderSide(color: KitsuneTheme.border),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(Icons.offline_bolt, 'Works Offline'),
                      _buildBadge(Icons.phone_android, 'Mobile-First'),
                      _buildBadge(Icons.auto_awesome, 'AI-Powered'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Features Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'Everything You Need.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KitsuneTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [KitsuneTheme.kitsuneOrange, KitsuneTheme.kitsuneViolet],
                    ).createShader(bounds),
                    child: const Text(
                      'Nothing You Don\'t.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'One platform. Every tool. Zero external accounts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: KitsuneTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.terminal,
                        title: 'Kitsuné Shell',
                        description: 'Full Linux terminal with package manager',
                        color: KitsuneTheme.kitsuneOrange,
                      ),
                      _buildFeatureCard(
                        icon: Icons.auto_awesome,
                        title: 'AI Swarm',
                        description: '5 specialized agents working in parallel',
                        color: KitsuneTheme.kitsuneViolet,
                      ),
                      _buildFeatureCard(
                        icon: Icons.database,
                        title: 'KitsunéDB',
                        description: 'Built-in backend with auth & storage',
                        color: KitsuneTheme.kitsuneTeal,
                      ),
                      _buildFeatureCard(
                        icon: Icons.cloud_upload,
                        title: 'One-Tap Deploy',
                        description: 'App + DB + Domain + SSL in 60s',
                        color: KitsuneTheme.kitsuneTeal,
                      ),
                      _buildFeatureCard(
                        icon: Icons.mic,
                        title: 'Voice Builder',
                        description: 'Talk to build. Walk and code.',
                        color: KitsuneTheme.kitsuneOrange,
                      ),
                      _buildFeatureCard(
                        icon: Icons.security,
                        title: 'AI Project Doctor',
                        description: 'Continuous monitoring & auto-fixes',
                        color: KitsuneTheme.kitsuneOrange,
                      ),
                      _buildFeatureCard(
                        icon: Icons.code,
                        title: 'Visual Builder',
                        description: 'Drag-and-drop UI construction',
                        color: KitsuneTheme.kitsuneViolet,
                      ),
                      _buildFeatureCard(
                        icon: Icons.offline_bolt,
                        title: 'Offline-First',
                        description: 'Work for days without internet',
                        color: KitsuneTheme.kitsuneTeal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Terminal Demo
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KitsuneTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: KitsuneTheme.error, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: KitsuneTheme.warning, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: KitsuneTheme.kitsuneTeal, shape: BoxShape.circle)),
                      const SizedBox(width: 16),
                      const Text('kitsune@byte:~/myapp', style: TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTerminalLine('\$ kit init react myapp', isCommand: true),
                  _buildTerminalLine('✓ Project initialized with React + TypeScript', isSuccess: true),
                  _buildTerminalLine('✓ KitsunéDB configured (SQLite, local)'),
                  _buildTerminalLine('✓ AI Swarm agents activated'),
                  const SizedBox(height: 12),
                  _buildTerminalLine('\$ kit add auth', isCommand: true),
                  _buildTerminalLine('✓ Authentication flow generated', isSuccess: true),
                  _buildTerminalLine('✓ Security Agent: No vulnerabilities detected'),
                  const SizedBox(height: 12),
                  _buildTerminalLine('\$ kit deploy', isCommand: true),
                  _buildTerminalLine('🚀 Live at https://myapp.kitsune.io', isHighlight: true),
                  const SizedBox(height: 12),
                  _buildTerminalLine('🦊 Swarm: "Your image uploads are costing \$18/month. Use WebP conversion?"', isAi: true),
                ],
              ),
            ),
          ),

          // CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Ready to Build Without Limits?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KitsuneTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Join thousands of builders shipping apps from their phones, tablets, and desktops — online or offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: KitsuneTheme.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Start Building Free'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KitsuneTheme.kitsuneOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: KitsuneTheme.border)),
              ),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2026 Kitsuné Byte. All rights reserved.',
                    style: TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFoxIcon(size: 32),
        const SizedBox(width: 8),
        const Text(
          'Kitsun',
          style: TextStyle(
            color: KitsuneTheme.kitsuneOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'é',
          style: TextStyle(
            color: KitsuneTheme.kitsuneOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          ' Byte',
          style: TextStyle(
            color: KitsuneTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedFox({double size = 120}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: _buildFoxIcon(size: size),
        );
      },
    );
  }

  Widget _buildFoxIcon({double size = 40}) {
    return CustomPaint(
      size: Size(size, size),
      painter: FoxIconPainter(),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: KitsuneTheme.textTertiary, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: KitsuneTheme.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KitsuneTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KitsuneTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
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
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalLine(String text, {
    bool isCommand = false,
    bool isSuccess = false,
    bool isHighlight = false,
    bool isAi = false,
  }) {
    Color color;
    if (isCommand) color = KitsuneTheme.kitsuneTeal;
    else if (isSuccess) color = KitsuneTheme.kitsuneTeal;
    else if (isHighlight) color = KitsuneTheme.kitsuneTeal;
    else if (isAi) color = KitsuneTheme.kitsuneViolet;
    else color = KitsuneTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

// Custom painter for the fox icon
class FoxIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Fox head shape
    path.moveTo(w * 0.5, h * 0.15);
    path.lineTo(w * 0.3, h * 0.35);
    path.lineTo(w * 0.2, h * 0.25);
    path.lineTo(w * 0.15, h * 0.45);
    path.lineTo(w * 0.25, h * 0.55);
    path.lineTo(w * 0.2, h * 0.75);
    path.lineTo(w * 0.35, h * 0.85);
    path.lineTo(w * 0.5, h * 0.75);
    path.lineTo(w * 0.65, h * 0.85);
    path.lineTo(w * 0.8, h * 0.75);
    path.lineTo(w * 0.75, h * 0.55);
    path.lineTo(w * 0.85, h * 0.45);
    path.lineTo(w * 0.8, h * 0.25);
    path.lineTo(w * 0.7, h * 0.35);
    path.close();

    canvas.drawPath(path, paint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF0D0D0D);
    canvas.drawCircle(Offset(w * 0.38, h * 0.48), w * 0.04, eyePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.48), w * 0.04, eyePaint);

    // Nose
    final nosePath = Path();
    nosePath.moveTo(w * 0.5, h * 0.55);
    nosePath.lineTo(w * 0.47, h * 0.6);
    nosePath.lineTo(w * 0.53, h * 0.6);
    nosePath.close();
    canvas.drawPath(nosePath, eyePaint);

    // Ear accents (violet)
    final accentPaint = Paint()..color = const Color(0xFF7B61FF).withOpacity(0.8);
    final leftEar = Path();
    leftEar.moveTo(w * 0.3, h * 0.35);
    leftEar.lineTo(w * 0.25, h * 0.2);
    leftEar.lineTo(w * 0.35, h * 0.3);
    leftEar.close();
    canvas.drawPath(leftEar, accentPaint);

    final rightEar = Path();
    rightEar.moveTo(w * 0.7, h * 0.35);
    rightEar.lineTo(w * 0.75, h * 0.2);
    rightEar.lineTo(w * 0.65, h * 0.3);
    rightEar.close();
    canvas.drawPath(rightEar, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
