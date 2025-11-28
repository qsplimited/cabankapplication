// File: lib/theme/app_text_styles.dart

import 'package:flutter/material.dart';

// Defines the text style mapping based on the default text theme and the desired primary text color.
TextTheme createCorporateTextTheme(TextTheme base, Color defaultColor) {
  // Use a reliable font (like Roboto) for professional banking screens
  const String? defaultFontFamily = 'Roboto';

  return base.copyWith(
    // Titles & Large Headings (e.g., Screen Header, App Bar)
    displayLarge: base.displayLarge?.copyWith(fontFamily: defaultFontFamily, color: defaultColor, fontWeight: FontWeight.w900, fontSize: 40),
    headlineMedium: base.headlineMedium?.copyWith(fontFamily: defaultFontFamily, color: defaultColor, fontWeight: FontWeight.bold, fontSize: 26),
    titleLarge: base.titleLarge?.copyWith(fontFamily: defaultFontFamily, color: defaultColor, fontWeight: FontWeight.w700, fontSize: 20),
    titleMedium: base.titleMedium?.copyWith(fontFamily: defaultFontFamily, color: defaultColor, fontWeight: FontWeight.w600, fontSize: 16),
    titleSmall: base.titleSmall?.copyWith(fontFamily: defaultFontFamily, color: defaultColor, fontWeight: FontWeight.w500, fontSize: 14),

    // Body Text (e.g., Paragraphs, Main content)
    bodyLarge: base.bodyLarge?.copyWith(fontFamily: defaultFontFamily, color: defaultColor, fontSize: 16),
    bodyMedium: base.bodyMedium?.copyWith(fontFamily: defaultFontFamily, color: defaultColor.withOpacity(0.85), fontSize: 14),

    // Labels & Buttons (e.g., Button Text, Form Labels)
    labelLarge: base.labelLarge?.copyWith(fontFamily: defaultFontFamily, color: defaultColor, fontWeight: FontWeight.bold, fontSize: 14),
    labelSmall: base.labelSmall?.copyWith(fontFamily: defaultFontFamily, color: defaultColor.withOpacity(0.6), fontSize: 12),
  );
}