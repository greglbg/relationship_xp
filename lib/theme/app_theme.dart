import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // ARAGOTH COLOR PALETTE
  // ============================================================

  static const Color parchment = Color(0xFFF2E6C9);
  static const Color parchmentLight = Color(0xFFFFF8E8);
  static const Color forestGreen = Color(0xFF284638);
  static const Color antiqueGold = Color(0xFFB58A43);
  static const Color weatheredLeather = Color(0xFF604332);
  static const Color darkInk = Color(0xFF29251F);
  static const Color arcaneBlue = Color(0xFF527F91);

  // ============================================================
  // LIGHT THEME — ADVENTURER'S JOURNAL
  // ============================================================

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: forestGreen,
      onPrimary: parchmentLight,
      primaryContainer: const Color(0xFFDCE7D8),
      onPrimaryContainer: forestGreen,
      secondary: weatheredLeather,
      onSecondary: parchmentLight,
      secondaryContainer: const Color(0xFFEAD8BF),
      onSecondaryContainer: darkInk,
      tertiary: arcaneBlue,
      onTertiary: Colors.white,
      surface: parchmentLight,
      onSurface: darkInk,
      outline: antiqueGold,
      outlineVariant: const Color(0xFFD6C39C),
    );

    final baseTextTheme = ThemeData.light().textTheme;

    final fantasyTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: 'serif',
        color: darkInk,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: 'serif',
        color: darkInk,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: 'serif',
        color: darkInk,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: 'serif',
        color: darkInk,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: 'serif',
        color: darkInk,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: 'serif',
        color: forestGreen,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: 'serif',
        color: darkInk,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: darkInk,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: darkInk,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: weatheredLeather,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // General page appearance
      scaffoldBackgroundColor: parchment,

      textTheme: fantasyTextTheme,

      // ========================================================
      // APP BARS
      // ========================================================

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: forestGreen,
        foregroundColor: parchmentLight,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: parchmentLight,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: parchmentLight,
        ),
      ),

      // ========================================================
      // CARDS — PARCHMENT PANELS
      // ========================================================

      cardTheme: CardThemeData(
        color: parchmentLight,
        elevation: 2,
        shadowColor: weatheredLeather.withValues(alpha: 0.25),
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: antiqueGold,
            width: 1,
          ),
        ),
      ),

      // ========================================================
      // PRIMARY BUTTONS
      // ========================================================

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: parchmentLight,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: antiqueGold,
              width: 1,
            ),
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTONS
      // ========================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestGreen,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(
            color: antiqueGold,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parchmentLight,
        labelStyle: const TextStyle(
          color: weatheredLeather,
        ),
        hintStyle: const TextStyle(
          color: weatheredLeather,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: antiqueGold,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: antiqueGold,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: forestGreen,
            width: 2,
          ),
        ),
      ),

      // ========================================================
      // DIVIDERS
      // ========================================================

      dividerTheme: const DividerThemeData(
        color: antiqueGold,
        thickness: 1,
        space: 24,
      ),

      // ========================================================
      // FLOATING ACTION BUTTONS
      // ========================================================

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: antiqueGold,
        foregroundColor: darkInk,
      ),

      // ========================================================
      // PROGRESS INDICATORS
      // ========================================================

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: forestGreen,
        linearTrackColor: Color(0xFFD6C39C),
      ),
    );
  }
}