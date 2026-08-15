import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Research-terminal aesthetic: deep graphite + teal primary + indigo secondary.
class AppTheme {
  // Surfaces
  static const Color bg = Color(0xFF0D1117);
  static const Color card = Color(0xFF161B22);
  static const Color cardElevated = Color(0xFF1C2330);
  static const Color cardBorder = Color(0xFF30363D);
  static const Color border = cardBorder;

  // Accents
  static const Color accent = Color(0xFF2DD4BF); // teal
  static const Color accentSoft = Color(0x332DD4BF);
  static const Color indigo = Color(0xFF818CF8);
  static const Color indigoSoft = Color(0x33818CF8);
  static const Color gold = Color(0xFFD4A574); // restrained emphasis only

  // Semantic
  static const Color green = Color(0xFF34D399);
  static const Color red = Color(0xFFF87171);
  static const Color yellow = Color(0xFFFBBF24);

  // Text
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static BoxDecoration cardDecoration({Color? borderColor, Color? color}) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderColor ?? cardBorder, width: 1),
        boxShadow: cardShadow,
      );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      cardColor: card,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: indigo,
        surface: card,
        onPrimary: bg,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : textMuted,
          );
        }),
      ),
    );
  }

  static TextStyle get monoTitle => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.5,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
        letterSpacing: 0.2,
      );

  // Legacy aliases so existing screens compile during transition
  static TextStyle get serifTitle => monoTitle;
  static TextStyle get serifSmall => sectionTitle;
}
