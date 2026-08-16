import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// InvestIQ 2.0 — Visual Intelligence design system.
///
/// Philosophy: Deep space + luminous data.
/// Level 0 Canvas → Level 1 Surface → Level 2 Data → Level 3 Focus.
/// Borders are rare. Colour is semantic, never decorative spam.
class AppTheme {
  // ─── LEVEL 0 — CANVAS ───────────────────────────────────────────
  static const Color bg = Color(0xFF07090D);
  static const Color bgAlt = Color(0xFF0A0C11);

  // ─── LEVEL 1 — SURFACE ──────────────────────────────────────────
  static const Color surface = Color(0xFF0D1118);
  static const Color surfaceElevated = Color(0xFF131923);
  static const Color surfaceHover = Color(0xFF1A2030);

  // Borders — hairline, low contrast (avoid boxing everything)
  static const Color border = Color(0x14FFFFFF); // ~8% white
  static const Color borderSubtle = Color(0x0AFFFFFF);
  static const Color borderFocus = Color(0x28FFFFFF);

  // Legacy aliases
  static const Color card = surface;
  static const Color cardElevated = surfaceElevated;
  static const Color cardBorder = border;

  // ─── LEVEL 3 — FOCUS (semantic, used sparingly) ─────────────────
  /// Brand / neutral intelligence — not "good"
  static const Color accent = Color(0xFF27E0C0);
  static const Color accentSoft = Color(0x1A27E0C0);
  static const Color accentMuted = Color(0xFF1A9B84);

  /// Research / analytical highlight
  static const Color violet = Color(0xFF8B7CFF);
  static const Color violetSoft = Color(0x1A8B7CFF);
  static const Color indigo = violet;
  static const Color indigoSoft = violetSoft;

  /// Positive performance
  static const Color green = Color(0xFF32D583);
  static const Color greenSoft = Color(0x1A32D583);

  /// Negative performance
  static const Color red = Color(0xFFFF6B78);
  static const Color redSoft = Color(0x1AFF6B78);

  /// Caution / attention
  static const Color yellow = Color(0xFFF6C85F);
  static const Color yellowSoft = Color(0x1AF6C85F);
  static const Color gold = yellow;

  // Accent palette for user preference
  static const Color accentTeal = Color(0xFF27E0C0);
  static const Color accentBlue = Color(0xFF5B8CFF);
  static const Color accentViolet = Color(0xFF8B7CFF);
  static const Color accentAmber = Color(0xFFF6C85F);
  static const Color accentEmerald = Color(0xFF32D583);

  // ─── TEXT HIERARCHY ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF3F5F7);
  static const Color textSecondary = Color(0xFF8B93A3);
  static const Color textMuted = Color(0xFF5A6374);
  static const Color textInverse = Color(0xFF07090D);

  // ─── RADIUS ─────────────────────────────────────────────────────
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 20;

  // ─── MOTION ─────────────────────────────────────────────────────
  static const Duration micro = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration data = Duration(milliseconds: 400);
  static const Duration hero = Duration(milliseconds: 560);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;

  // ─── GRADIENTS ──────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF27E0C0), Color(0xFF1A9B84)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF131923), Color(0xFF0D1118)],
  );

  static List<BoxShadow> get glowAccent => [
        BoxShadow(
          color: accent.withOpacity(0.12),
          blurRadius: 24,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardShadow => const [];

  // ─── DECORATIONS ────────────────────────────────────────────────
  /// Prefer this over heavy bordered cards. Surfaces speak quietly.
  static BoxDecoration surfaceDecoration({
    Color? color,
    double radius = radiusMd,
    bool elevated = false,
  }) =>
      BoxDecoration(
        color: color ?? (elevated ? surfaceElevated : surface),
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration cardDecoration({Color? borderColor, Color? color}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderColor ?? border, width: 1),
      );

  static Widget sectionRule() => Container(
        height: 1,
        color: borderSubtle,
        margin: const EdgeInsets.symmetric(vertical: 4),
      );

  // ─── THEME DATA ─────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      cardColor: surface,
      dividerColor: borderSubtle,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: violet,
        surface: surface,
        onPrimary: textInverse,
        onSurface: textPrimary,
        error: red,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: textSecondary, size: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentSoft,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accent : textMuted,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: accentSoft,
        labelStyle: const TextStyle(fontSize: 12, color: textSecondary),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ─── TYPOGRAPHY SCALE ───────────────────────────────────────────
  static TextStyle get display => GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 28,
        letterSpacing: -0.7,
        height: 1.15,
      );

  static TextStyle get title => GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 17,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        color: textMuted,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 1.2,
      );

  static TextStyle get body => GoogleFonts.inter(
        color: textSecondary,
        fontWeight: FontWeight.w400,
        fontSize: 13,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.inter(
        color: textMuted,
        fontWeight: FontWeight.w400,
        fontSize: 11,
        height: 1.35,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: -0.3,
      );

  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 26,
        letterSpacing: -0.6,
      );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: -0.2,
      );

  // Legacy aliases
  static TextStyle get monoTitle => monoLarge;
  static TextStyle get sectionTitle => title;
  static TextStyle get serifTitle => display;
  static TextStyle get serifSmall => title;

  // ─── SEMANTIC HELPERS ───────────────────────────────────────────
  static Color performance(double changePct) {
    if (changePct > 0.05) return green;
    if (changePct < -0.05) return red;
    return textSecondary;
  }

  static Color setupColor(double score) {
    if (score >= 75) return green;
    if (score >= 60) return accent;
    if (score >= 40) return textMuted;
    return red;
  }

  static String setupLabel(double score) {
    if (score >= 75) return 'Strong';
    if (score >= 60) return 'Watch';
    if (score >= 40) return 'Neutral';
    return 'Weak';
  }
}
