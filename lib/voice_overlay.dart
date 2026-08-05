import 'package:flutter/material.dart';
import 'dart:async';
import 'kitsune_theme_v3.dart';

class VoiceOverlayButton extends StatefulWidget {
  const VoiceOverlayButton({super.key});
  @override State<VoiceOverlayButton> createState() => _VoiceOverlayButtonState();
}

class _VoiceOverlayButtonState extends State<VoiceOverlayButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _isListening = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [KitsuneTheme.foxOrange, KitsuneTheme.foxGlow]),
              boxShadow: _isListening ? [
                BoxShadow(
                  color: KitsuneTheme.foxOrange.withOpacity(0.4 * (0.5 + 0.5 * _pulseController.value)),
                  blurRadius: 20 + 10 * _pulseController.value,
                  spreadRadius: 2 + 4 * _pulseController.value,
                ),
              ] : [
                BoxShadow(color: KitsuneTheme.foxOrange.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
              ],
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: KitsuneTheme.deepCharcoal,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
