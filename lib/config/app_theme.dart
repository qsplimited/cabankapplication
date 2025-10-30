import 'package:flutter/material.dart';

// Helper function to create a MaterialColor from a single Color value
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

// --- COMPANY STANDARD: COLORS ---
// Define base colors
const Color _basePrimaryColor = Color(0xFF003366); // Deep Navy Blue
const Color _baseSecondaryColor = Color(0xFF6699FF); // Bright Accent Blue
const Color _baseSuccessColor = Color(0xFF1E88E5); // Blue for Credit/Success
const Color _baseErrorColor = Color(0xFFD32F2F); // Red for errors/debits
const Color _baseTertiaryColor = Color(0xFFFFA500); // Orange for general use/icons

// Create MaterialColor swatches so we can use .shadeXXX
final MaterialColor _primaryColor = createMaterialColor(_basePrimaryColor);
final MaterialColor _successColor = createMaterialColor(_baseSuccessColor);
final MaterialColor _errorColor = createMaterialColor(_baseErrorColor);


// --- COMPANY STANDARD: CONSTANTS ---

/// Utility class for consistent spacing values used throughout the app.
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Utility class for consistent border radii used throughout the app.
class AppBorders {
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double smallRadius = 8.0; // Added for smaller elements like icons/badges
}

/// Utility class for accessing company standard colors.
class AppColors {
  static MaterialColor get primary => _primaryColor;
  static Color get secondary => _baseSecondaryColor;
  static Color get tertiary => _baseTertiaryColor; // Expose tertiary color
  static MaterialColor get success => _successColor;
  static MaterialColor get error => _errorColor;

  // Additional frequently used colors
  static Color get lightBackground => Colors.grey.shade50;
  static Color get cardBackground => Colors.white;
  static Color get textPrimary => Colors.grey.shade900;
  static Color get textSecondary => Colors.grey.shade600;
}


// --- THEME DATA CONFIGURATION ---
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // 1. Color Scheme Definition
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.cardBackground,
          background: AppColors.lightBackground,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        fontFamily: 'Roboto',

        // 2. Text Theme (Typography)
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),

        // 3. Card Theme Data - REMOVED TO PREVENT TYPE ERROR

        // 4. Global Button Style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
            textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600
            ),
            elevation: 4,
          ),
        ),

        // 5. Global Input Field Style
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        ),

        // 6. AppBar Theme (Consistent look for all screens)
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        )
    );
  }
}
