import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFF0B0F19);
  static const Color card = Color(0xFF141B2D);
  static const Color cardBorder = Color(0xFF1E2A44);
  static const Color accent = Color(0xFF3B82F6);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderColor ?? cardBorder),
        boxShadow: cardShadow,
      );

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      cardColor: card,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
      ),
      useMaterial3: true,
    );
  }
}
