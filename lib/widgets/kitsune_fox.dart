import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

/// Compact brand mark for app bars / nav — simple glowing fox head.
class KitsuneMark extends StatelessWidget {
  final double size;
  final bool showGlow;

  const KitsuneMark({super.key, this.size = 32, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: KitsuneTheme.royalGradient,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: KitsuneTheme.lilac.withOpacity(0.45),
                  blurRadius: size * 0.4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.pets,
        size: size * 0.55,
        color: KitsuneTheme.pearl,
      ),
    );
  }
}

/// Full logo image from brand assets.
class KitsuneLogoImage extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const KitsuneLogoImage({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/kitsune_logo.jpg',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => Icon(
        Icons.pets,
        size: height ?? 80,
        color: KitsuneTheme.lilac,
      ),
    );
  }
}

/// Animated fox companion that bounces / floats around the UI.
/// Modes: idle bounce, working pulse, celebrating spin.
enum FoxMood { idle, working, celebrating, listening }

class AnimatedKitsuneFox extends StatefulWidget {
  final FoxMood mood;
  final double size;
  final VoidCallback? onTap;

  const AnimatedKitsuneFox({
    super.key,
    this.mood = FoxMood.idle,
    this.size = 56,
    this.onTap,
  });

  @override
  State<AnimatedKitsuneFox> createState() => _AnimatedKitsuneFoxState();
}

class _AnimatedKitsuneFoxState extends State<AnimatedKitsuneFox>
    with TickerProviderStateMixin {
  late AnimationController _bounce;
  late AnimationController _pulse;
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _syncMood();
  }

  @override
  void didUpdateWidget(covariant AnimatedKitsuneFox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) _syncMood();
  }

  void _syncMood() {
    switch (widget.mood) {
      case FoxMood.idle:
        _pulse.stop();
        _spin.stop();
        if (!_bounce.isAnimating) _bounce.repeat(reverse: true);
        break;
      case FoxMood.working:
      case FoxMood.listening:
        _bounce.stop();
        _spin.stop();
        if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
        break;
      case FoxMood.celebrating:
        _bounce.stop();
        _pulse.stop();
        _spin.forward(from: 0).then((_) {
          if (mounted) _bounce.repeat(reverse: true);
        });
        break;
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounce, _pulse, _spin]),
        builder: (context, _) {
          double dy = 0;
          double scale = 1;
          double angle = 0;
          double glow = 0.35;

          switch (widget.mood) {
            case FoxMood.idle:
              dy = Curves.easeInOut.transform(_bounce.value) * -6;
              glow = 0.3 + _bounce.value * 0.15;
              break;
            case FoxMood.working:
            case FoxMood.listening:
              scale = 1.0 + _pulse.value * 0.12;
              glow = 0.4 + _pulse.value * 0.35;
              break;
            case FoxMood.celebrating:
              angle = _spin.value * math.pi * 2;
              scale = 1.0 + math.sin(_spin.value * math.pi) * 0.2;
              glow = 0.6;
              break;
          }

          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        KitsuneTheme.foxGlow,
                        KitsuneTheme.foxOrange,
                        KitsuneTheme.royalPurple,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KitsuneTheme.cyanEyes.withOpacity(glow * 0.5),
                        blurRadius: 18 + glow * 12,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: KitsuneTheme.lilac.withOpacity(glow * 0.4),
                        blurRadius: 28,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        size: widget.size * 0.5,
                        color: KitsuneTheme.pearl,
                      ),
                      // cyan "eyes" sparkle
                      Positioned(
                        top: widget.size * 0.32,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _eye(widget.size * 0.06),
                            SizedBox(width: widget.size * 0.12),
                            _eye(widget.size * 0.06),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _eye(double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KitsuneTheme.cyanEyes,
          boxShadow: [
            BoxShadow(
              color: KitsuneTheme.cyanEyes.withOpacity(0.8),
              blurRadius: 4,
            ),
          ],
        ),
      );
}

/// Floating fox that drifts slowly across a corner of the screen.
class FloatingFoxOverlay extends StatefulWidget {
  final FoxMood mood;
  final VoidCallback? onTap;

  const FloatingFoxOverlay({
    super.key,
    this.mood = FoxMood.idle,
    this.onTap,
  });

  @override
  State<FloatingFoxOverlay> createState() => _FloatingFoxOverlayState();
}

class _FloatingFoxOverlayState extends State<FloatingFoxOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_drift.value);
        return Positioned(
          right: 12 + t * 18,
          bottom: 80 + math.sin(t * math.pi) * 12,
          child: child!,
        );
      },
      child: AnimatedKitsuneFox(
        mood: widget.mood,
        size: 48,
        onTap: widget.onTap,
      ),
    );
  }
}
