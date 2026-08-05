import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand palette derived from the official Kitsune Byte logo:
/// royal / lilac purple + opal / pearl iridescence,
/// with fox-fire orange + cyan eyes as accent energy.
class KitsuneTheme {
  // ── Core brand ──────────────────────────────────────────────
  static const Color royalPurple = Color(0xFF6B3FA0);
  static const Color lilac = Color(0xFF9B7EBD);
  static const Color softLilac = Color(0xFFC4A8E0);
  static const Color deepViolet = Color(0xFF3D1F6B);

  // Opal / pearl iridescence
  static const Color pearl = Color(0xFFF2EAF8);
  static const Color opal = Color(0xFFE8D5F2);
  static const Color opalCyan = Color(0xFFB8E0F0);
  static const Color opalGold = Color(0xFFF5D9A8);
  static const Color mistPearl = Color(0xFFD4C4E0);

  // Fox energy (from logo)
  static const Color foxOrange = Color(0xFFFF6B2C);
  static const Color foxGlow = Color(0xFFFF9A5C);
  static const Color gold = Color(0xFFFFB347);
  static const Color cyanEyes = Color(0xFF00E5C0);
  static const Color emberRed = Color(0xFFE85D3E);

  // Surfaces
  static const Color voidBlack = Color(0xFF0A0612);
  static const Color deepCharcoal = Color(0xFF120A1C);
  static const Color surfacePurple = Color(0xFF1E1230);
  static const Color cardSurface = Color(0xFF26183A);
  static const Color warmCream = Color(0xFFF5E6F0);
  static const Color mistSilver = Color(0xFFB8A9C4);

  // Aliases kept for older call-sites
  static const Color pearlOpal = pearl;
  static const Color shadowAuburn = surfacePurple;

  // ── Gradients ───────────────────────────────────────────────
  static const LinearGradient foxGradient = LinearGradient(
    colors: [foxOrange, foxGlow, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient royalGradient = LinearGradient(
    colors: [deepViolet, royalPurple, lilac],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient opalGradient = LinearGradient(
    colors: [opal, softLilac, opalCyan, opalGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient terminalGlow = LinearGradient(
    colors: [Color(0xFF1A0F2E), Color(0xFF0A0612)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Typography ──────────────────────────────────────────────
  static TextStyle displayLarge({Color? color, double? fontSize, FontWeight? fontWeight}) =>
      TextStyle(
        fontFamily: 'Satoshi',
        fontSize: fontSize ?? 32,
        fontWeight: fontWeight ?? FontWeight.w800,
        color: color ?? pearl,
        letterSpacing: -0.5,
      );

  static TextStyle displayMedium({Color? color, double? fontSize, FontWeight? fontWeight}) =>
      TextStyle(
        fontFamily: 'Satoshi',
        fontSize: fontSize ?? 24,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color ?? pearl,
      );

  static TextStyle bodyLarge({Color? color, double? fontSize, FontWeight? fontWeight}) =>
      TextStyle(
        fontFamily: 'Satoshi',
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? mistPearl,
        height: 1.5,
      );

  static TextStyle bodyMono({Color? color, double? fontSize, FontWeight? fontWeight}) =>
      TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: fontSize ?? 13.5,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? cyanEyes,
        height: 1.45,
      );

  static TextStyle label({Color? color, double? fontSize, FontWeight? fontWeight}) =>
      TextStyle(
        fontFamily: 'Satoshi',
        fontSize: fontSize ?? 12,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? mistSilver,
        letterSpacing: 0.5,
      );

  // ── ThemeData ───────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: voidBlack,
        primaryColor: royalPurple,
        colorScheme: const ColorScheme.dark(
          primary: royalPurple,
          secondary: lilac,
          tertiary: cyanEyes,
          surface: surfacePurple,
          onSurface: pearl,
          error: emberRed,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: deepCharcoal.withOpacity(0.95),
          elevation: 0,
          titleTextStyle: displayMedium(),
          iconTheme: const IconThemeData(color: softLilac),
        ),
        cardTheme: CardTheme(
          color: cardSurface.withOpacity(0.85),
          elevation: 8,
          shadowColor: royalPurple.withOpacity(0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: deepCharcoal.withOpacity(0.97),
          selectedItemColor: softLilac,
          unselectedItemColor: mistSilver,
          type: BottomNavigationBarType.fixed,
          elevation: 16,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: royalPurple,
          foregroundColor: pearl,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfacePurple.withOpacity(0.6),
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
          color: mistSilver.withOpacity(0.15),
          thickness: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfacePurple,
          selectedColor: royalPurple.withOpacity(0.5),
          labelStyle: label(color: pearl),
          side: BorderSide(color: lilac.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );

  static BoxDecoration glassCard = BoxDecoration(
    color: cardSurface.withOpacity(0.55),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: softLilac.withOpacity(0.18)),
    boxShadow: [
      BoxShadow(
        color: royalPurple.withOpacity(0.12),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration glowBorder = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: lilac.withOpacity(0.35)),
    boxShadow: [
      BoxShadow(
        color: cyanEyes.withOpacity(0.12),
        blurRadius: 14,
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration opalGlass = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      colors: [
        softLilac.withOpacity(0.15),
        opalCyan.withOpacity(0.08),
        royalPurple.withOpacity(0.12),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: pearl.withOpacity(0.2)),
  );

  static Duration get fast => const Duration(milliseconds: 200);
  static Duration get medium => const Duration(milliseconds: 400);
  static Duration get slow => const Duration(milliseconds: 800);

  static SystemUiOverlayStyle get systemUi => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: voidBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      );
}

/// Soft opal shimmer that sweeps across children.
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
                KitsuneTheme.royalPurple.withOpacity(0.15),
                KitsuneTheme.softLilac.withOpacity(0.4),
                KitsuneTheme.opalCyan.withOpacity(0.2),
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
