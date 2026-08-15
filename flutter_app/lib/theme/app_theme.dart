import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// InvestIQ 2.0 — data-first research terminal.
/// Canvas + sections + visualizations. Cards only when grouping related data.
class AppTheme {
  // Base canvas
  static const Color bg = Color(0xFF090B10);
  static const Color surface = Color(0xFF11151D);
  static const Color surfaceElevated = Color(0xFF171C25);
  static const Color border = Color(0xFF232A36);
  static const Color borderSubtle = Color(0xFF1A1F28);

  // Legacy aliases used across screens
  static const Color card = surface;
  static const Color cardElevated = surfaceElevated;
  static const Color cardBorder = border;

  // Brand — restrained mint, not neon
  static const Color accent = Color(0xFF3DDBB0);
  static const Color accentSoft = Color(0x1A3DDBB0);
  static const Color accentMuted = Color(0xFF2A9B7A);

  // Secondary highlight (rare)
  static const Color violet = Color(0xFF8B9CFF);
  static const Color violetSoft = Color(0x1A8B9CFF);
  static const Color indigo = violet;
  static const Color indigoSoft = violetSoft;

  // Semantic
  static const Color green = Color(0xFF34D399);
  static const Color red = Color(0xFFF07178);
  static const Color yellow = Color(0xFFE6B35A);
  static const Color gold = yellow; // legacy

  // Text hierarchy
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9299A8);
  static const Color textMuted = Color(0xFF5C6575);

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3DDBB0), Color(0xFF2A9B7A)],
  );

  static List<BoxShadow> get cardShadow => const [];

  static BoxDecoration cardDecoration({Color? borderColor, Color? color}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderColor ?? border, width: 1),
      );

  /// Hairline divider for section breaks (prefer over cards).
  static Widget sectionRule() => Container(
        height: 1,
        color: borderSubtle,
        margin: const EdgeInsets.symmetric(vertical: 4),
      );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      cardColor: surface,
      dividerColor: borderSubtle,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: violet,
        surface: surface,
        onPrimary: bg,
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
    );
  }

  // Typography scale
  static TextStyle get display => GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 28,
        letterSpacing: -0.6,
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
        letterSpacing: 1.1,
      );

  static TextStyle get body => GoogleFonts.inter(
        color: textSecondary,
        fontWeight: FontWeight.w400,
        fontSize: 13,
        height: 1.45,
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
        fontSize: 24,
        letterSpacing: -0.5,
      );

  // Legacy aliases
  static TextStyle get monoTitle => monoLarge;
  static TextStyle get sectionTitle => title;
  static TextStyle get serifTitle => display;
  static TextStyle get serifSmall => title;
}
