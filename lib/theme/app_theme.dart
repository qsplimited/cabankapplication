// File: lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart'; // Ensure this is imported for createCorporateTextTheme
import 'app_dimensions.dart';

// ----------------------------------------------------------------
// Helper functions for theme building (REMOVED: _buildCardTheme)
// Inlining CardTheme creation to resolve compilation type error.
// ----------------------------------------------------------------

// The AppTheme class structure required by your main.dart
class AppTheme {
  // -------------------------
  // LIGHT THEME
  // -------------------------
  static ThemeData get lightTheme => _buildThemeData(
    colorScheme: const ColorScheme.light(
      primary: kAccentOrange, // <-- CHANGED: New primary color (Gold/Amber)
      secondary: kBrandNavy,
      surface: kLightSurface,
      background: kLightBackground,
      error: kErrorRed,
      onPrimary: kLightTextPrimary,// Text on the primary (Navy) button
      onSurface: kLightTextPrimary, // Text on card/container surface
      onBackground: kLightTextPrimary, // Text on screen background
      brightness: Brightness.light,
    ),
    isDark: false,
  );

  // -------------------------
  // DARK THEME
  // -------------------------
  static ThemeData get darkTheme => _buildThemeData(
    colorScheme: const ColorScheme.dark(
      primary: kBrandLightBlue,
      secondary: kAccentCyan,
      surface: kDarkSurface,
      background: kDarkBackground,
      error: kErrorRed,
      onPrimary: kDarkTextPrimary, // Text on the primary (Light Blue) button
      onSurface: kDarkTextPrimary, // Text on card/container surface
      onBackground: kDarkTextPrimary, // Text on screen background
      brightness: Brightness.dark,
    ),
    isDark: true,
  );
}

// ------------------------------------------------------------
// THEME BUILDER (SHARED BY LIGHT + DARK)
// ------------------------------------------------------------

ThemeData _buildThemeData({
  required ColorScheme colorScheme,
  required bool isDark,
}) {
  final base = isDark ? ThemeData.dark() : ThemeData.light();

  // Create the custom text theme based on the base text theme and the correct primary text color (onBackground).
  final textTheme =
  createCorporateTextTheme(base.textTheme, colorScheme.onBackground);

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    textTheme: textTheme,

    // ------------------------------------------------------------
    // 1. CARD THEME (FIXED with explicit type cast to resolve CardThemeData mismatch)
    // ------------------------------------------------------------
/*    cardTheme: CardTheme(
      color: colorScheme.surface,
      elevation: kCardElevation,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      shadowColor: colorScheme.onBackground.withOpacity(0.12),
      clipBehavior: Clip.antiAlias,
    ) as CardTheme?, // <-- Explicitly cast CardTheme to CardTheme?*/

    // ------------------------------------------------------------
    // 2. APP BAR THEME
    // ------------------------------------------------------------
    appBarTheme: AppBarTheme(
      color: colorScheme.surface,
      elevation: kCardElevation, // Reusing elevation constant
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),

    // ------------------------------------------------------------
    // 3. ELEVATED BUTTON THEME
    // ------------------------------------------------------------
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, kButtonHeight),
        padding: const EdgeInsets.symmetric(
          vertical: kPaddingMedium,
          horizontal: kPaddingLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSmall),
        ),
        elevation: kCardElevation, // Reusing elevation constant
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ------------------------------------------------------------
    // 4. INPUT DECORATION THEME
    // ------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        vertical: kPaddingMedium,
        horizontal: kPaddingSmall,
      ),
      labelStyle:
      textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      prefixIconColor: colorScheme.onSurface.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: BorderSide(
          color: isDark ? kDarkDivider : kLightDivider,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      // Error styles inherit from colorScheme.error by default, which is correct.
    ),
  );
}