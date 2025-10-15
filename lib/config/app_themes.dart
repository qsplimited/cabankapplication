import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Branding Colors (Define once) ---
const Color _cabankPrimary = Color(0xFF004D40); // Dark Teal
const Color _cabankAccent = Color(0xFF00796B); // Brighter Teal (for contrast)
const Color _lightBackground = Colors.white;
const Color _darkBackground = Color(0xFF121212); // Deep dark gray

// --- Shared Styling (Used in both themes) ---
const double _defaultBorderRadius = 8.0;

// --- 1. LIGHT MODE THEME ---
final lightTheme = ThemeData(
  // Core colors
  primarySwatch: Colors.teal, // Provides a range of teal shades
  primaryColor: _cabankPrimary,
  brightness: Brightness.light,
  useMaterial3: true,

  // Background/UI colors
  scaffoldBackgroundColor: _lightBackground,
  cardColor: Colors.white,

  // Typography
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
  ),

  // App Bar Style
  appBarTheme: const AppBarTheme(
    color: _cabankPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light, // Status bar icons are light
  ),

  // Button Styles (Matching your initial design)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _cabankPrimary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_defaultBorderRadius),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),


  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(_defaultBorderRadius)),
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(_defaultBorderRadius)),
      borderSide: BorderSide(color: _cabankPrimary, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.black54),
  ),
);


// --- 2. DARK MODE THEME ---
final darkTheme = ThemeData(
  // Core colors
  primarySwatch: Colors.teal,
  primaryColor: _cabankAccent, // Use brighter teal for visibility on dark background
  brightness: Brightness.dark,
  useMaterial3: true,

  // Background/UI colors
  scaffoldBackgroundColor: _darkBackground,
  cardColor: const Color(0xFF1E1E1E), // Slightly lighter than background for depth

  // Typography
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),

  // App Bar Style
  appBarTheme: const AppBarTheme(
    color: Colors.black, // True black background
    foregroundColor: Colors.white,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark, // Status bar icons are dark
  ),


  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _cabankAccent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_defaultBorderRadius),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),

  // Input Field Style
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(_defaultBorderRadius)),
      borderSide: BorderSide(color: Colors.white38),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(_defaultBorderRadius)),
      borderSide: BorderSide(color: _cabankAccent, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.white70),
  ),
);