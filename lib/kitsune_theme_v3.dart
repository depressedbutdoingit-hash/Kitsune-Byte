import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KitsuneTheme {
  static const Color foxOrange = Color(0xFFC85D31);
  static const Color foxGlow = Color(0xFFDE9461);
  static const Color gold = Color(0xFFF2A84E);
  static const Color cyanEyes = Color(0xFF8AC1CE);
  static const Color pearlOpal = Color(0xFFD9C4B7);
  static const Color deepCharcoal = Color(0xFF0D0505);
  static const Color warmCream = Color(0xFFF5E6D3);
  static const Color shadowAuburn = Color(0xFF3D1F14);
  static const Color mistSilver = Color(0xFFB8A99A);
  static const Color emberRed = Color(0xFFE85D3E);

  static const LinearGradient foxGradient = LinearGradient(
    colors: [foxOrange, foxGlow, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextStyle displayLarge({Color? color}) => TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: color ?? pearlOpal,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium({Color? color}) => TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color ?? pearlOpal,
  );

  static TextStyle bodyLarge({Color? color}) => TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? mistSilver,
    height: 1.5,
  );

  static TextStyle bodyMono({Color? color}) => TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? cyanEyes,
    height: 1.4,
  );

  static TextStyle label({Color? color}) => TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: color ?? mistSilver,
    letterSpacing: 0.5,
  );

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: deepCharcoal,
    primaryColor: foxOrange,
    colorScheme: const ColorScheme.dark(
      primary: foxOrange,
      secondary: foxGlow,
      tertiary: cyanEyes,
      surface: shadowAuburn,
      background: deepCharcoal,
      onBackground: pearlOpal,
      onSurface: pearlOpal,
      error: emberRed,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: deepCharcoal.withOpacity(0.9),
      elevation: 0,
      titleTextStyle: displayMedium(),
      iconTheme: const IconThemeData(color: foxGlow),
    ),
    cardTheme: CardTheme(
      color: shadowAuburn.withOpacity(0.6),
      elevation: 8,
      shadowColor: foxOrange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: deepCharcoal.withOpacity(0.95),
      selectedItemColor: foxOrange,
      unselectedItemColor: mistSilver,
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: foxOrange,
      foregroundColor: deepCharcoal,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: shadowAuburn.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cyanEyes, width: 2),
      ),
      labelStyle: label(color: mistSilver),
      hintStyle: bodyLarge(color: mistSilver.withOpacity(0.5)),
    ),
    dividerTheme: DividerThemeData(
      color: mistSilver.withOpacity(0.2),
      thickness: 1,
    ),
  );

  static BoxDecoration glassCard = BoxDecoration(
    color: shadowAuburn.withOpacity(0.4),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: mistSilver.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: foxOrange.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration glowBorder = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: foxGlow.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: foxGlow.withOpacity(0.15),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
  );

  static Duration get fast => const Duration(milliseconds: 200);
  static Duration get medium => const Duration(milliseconds: 400);
  static Duration get slow => const Duration(milliseconds: 800);

  static SystemUiOverlayStyle get systemUi => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: deepCharcoal,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}

class FoxShimmer extends StatefulWidget {
  final Widget child;
  const FoxShimmer({super.key, required this.child});

  @override
  State<FoxShimmer> createState() => _FoxShimmerState();
}

class _FoxShimmerState extends State<FoxShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                KitsuneTheme.foxOrange.withOpacity(0.1),
                KitsuneTheme.foxGlow.withOpacity(0.3),
                KitsuneTheme.gold.withOpacity(0.1),
              ],
              stops: [0.0, 0.5 + 0.5 * _controller.value, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
