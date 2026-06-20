import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BantayEskwela theme — "institutional crest" direction derived from the
/// Santa Ana Academy seal: forest green + antique gold on a warm parchment
/// canvas, with an engraved-feeling serif for titles.
class AppTheme {
  AppTheme._();

  static const Color forest = Color(0xFF1B5E33);
  static const Color pine = Color(0xFF0F3D20);
  static const Color gold = Color(0xFFC8A23A);
  static const Color parchment = Color(0xFFF7F5EF);
  static const Color ink = Color(0xFF1F2421);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      primary: forest,
      secondary: gold,
      brightness: Brightness.light,
    ).copyWith(surface: Colors.white);

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: parchment,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        // Serif, engraved feel for titles
        headlineSmall: GoogleFonts.lora(
            fontWeight: FontWeight.w600, color: ink, letterSpacing: 0.2),
        titleLarge: GoogleFonts.lora(
            fontWeight: FontWeight.w600, color: ink),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: forest,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parchment.withOpacity(0.5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: forest, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forest,
          side: const BorderSide(color: forest),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: forest),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.06),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; // keep institutional look consistent
}
