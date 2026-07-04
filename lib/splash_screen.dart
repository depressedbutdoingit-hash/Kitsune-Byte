import 'package:flutter/material.dart';
import 'dart:math' show pi;
import 'main.dart';
import 'kitsune_theme_v3.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _rotateAnim = Tween<double>(begin: -pi / 4, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeIn)),
    );

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.deepCharcoal,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Transform.rotate(
                    angle: _rotateAnim.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [KitsuneTheme.foxOrange, KitsuneTheme.foxGlow, Colors.transparent],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: KitsuneTheme.foxOrange.withOpacity(0.4 * _glowAnim.value),
                            blurRadius: 60 * _glowAnim.value,
                            spreadRadius: 20 * _glowAnim.value,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.pets,
                          size: 60,
                          color: KitsuneTheme.pearlOpal.withOpacity(_fadeAnim.value),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: _fadeAnim.value,
                  child: Column(
                    children: [
                      Text(
                        'KITSUNE',
                        style: KitsuneTheme.displayLarge(color: KitsuneTheme.pearlOpal).copyWith(
                          letterSpacing: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BYTE',
                        style: KitsuneTheme.displayMedium(color: KitsuneTheme.foxOrange).copyWith(
                          letterSpacing: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                Opacity(
                  opacity: _glowAnim.value,
                  child: SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      backgroundColor: KitsuneTheme.shadowAuburn,
                      valueColor: const AlwaysStoppedAnimation(KitsuneTheme.foxOrange),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
