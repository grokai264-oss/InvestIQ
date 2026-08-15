import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Private-ledger aesthetic: deep ink + brass gold.
class AppTheme {
  static const Color bg = Color(0xFF0A0C10);
  static const Color card = Color(0xFF12151C);
  static const Color cardBorder = Color(0xFF1E2430);
  static const Color accent = Color(0xFFC4A35A);
  static const Color accentSoft = Color(0x33C4A35A);
  static const Color green = Color(0xFF3D9B6E);
  static const Color red = Color(0xFFC45C5C);
  static const Color yellow = Color(0xFFD4A017);
  static const Color textPrimary = Color(0xFFF2EFE8);
  static const Color textSecondary = Color(0xFF9A958A);
  static const Color textMuted = Color(0xFF6B665C);

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4A35A), Color(0xFF8B7355)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderColor ?? cardBorder),
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
        secondary: accent,
        surface: card,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static TextStyle get serifTitle => GoogleFonts.playfairDisplay(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 28,
      );

  static TextStyle get serifSmall => GoogleFonts.playfairDisplay(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );
}
