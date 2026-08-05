import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';
import '../widgets/kitsune_fox.dart';
import 'projects_screen.dart';

/// Brand landing / home experience with full logo art.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enter;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _enter, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _enter, curve: const Interval(0.15, 0.9, curve: Curves.easeOutCubic)),
    );
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _enterApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProjectsScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: KitsuneTheme.voidBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient purple glow
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    KitsuneTheme.royalPurple.withOpacity(0.35),
                    KitsuneTheme.royalPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    KitsuneTheme.cyanEyes.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Top mark
                      Row(
                        children: [
                          const KitsuneMark(size: 36),
                          const SizedBox(width: 10),
                          Text(
                            'KITSUNÉ BYTE',
                            style: KitsuneTheme.label(
                              color: KitsuneTheme.softLilac,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ).copyWith(letterSpacing: 2.5),
                          ),
                        ],
                      ),
                      const Spacer(flex: 1),

                      // Hero logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: KitsuneTheme.lilac.withOpacity(0.35),
                                blurRadius: 40,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: KitsuneTheme.foxOrange.withOpacity(0.15),
                                blurRadius: 60,
                              ),
                            ],
                          ),
                          child: KitsuneLogoImage(
                            height: size.height * 0.38,
                            width: size.width - 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      Text(
                        'Build apps.\nMake magic.',
                        textAlign: TextAlign.center,
                        style: KitsuneTheme.displayLarge(
                          fontSize: 34,
                          color: KitsuneTheme.pearl,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your phone is the studio — AI terminal, visual builder,\nagent swarm & one-click deploy.',
                        textAlign: TextAlign.center,
                        style: KitsuneTheme.bodyLarge(
                          color: KitsuneTheme.mistPearl,
                          fontSize: 14,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _enterApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KitsuneTheme.royalPurple,
                            foregroundColor: KitsuneTheme.pearl,
                            elevation: 8,
                            shadowColor: KitsuneTheme.lilac.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Enter the Studio',
                                style: KitsuneTheme.displayMedium(
                                  fontSize: 17,
                                  color: KitsuneTheme.pearl,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Feature chips
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _FeatureChip(icon: Icons.terminal, label: 'AI Terminal'),
                          _FeatureChip(icon: Icons.dashboard_customize, label: 'Visual Builder'),
                          _FeatureChip(icon: Icons.hub, label: 'Agent Swarm'),
                          _FeatureChip(icon: Icons.rocket_launch, label: 'One-Click Deploy'),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating companion
          FloatingFoxOverlay(
            mood: FoxMood.idle,
            onTap: _enterApp,
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: KitsuneTheme.surfacePurple.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KitsuneTheme.lilac.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KitsuneTheme.cyanEyes),
          const SizedBox(width: 6),
          Text(label, style: KitsuneTheme.label(color: KitsuneTheme.pearl, fontSize: 11)),
        ],
      ),
    );
  }
}
