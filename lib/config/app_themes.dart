import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


const Color _cabankPrimary = Color(0xFF004D40);
const Color _cabankAccent = Color(0xFF00796B);
const Color _lightBackground = Colors.white;
const Color _darkBackground = Color(0xFF121212);


const double _defaultBorderRadius = 8.0;


final lightTheme = ThemeData(

  primarySwatch: Colors.teal,
  primaryColor: _cabankPrimary,
  brightness: Brightness.light,
  useMaterial3: true,


  scaffoldBackgroundColor: _lightBackground,
  cardColor: Colors.white,


  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
  ),


  appBarTheme: const AppBarTheme(
    color: _cabankPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),


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



final darkTheme = ThemeData(
  // Core colors
  primarySwatch: Colors.teal,
  primaryColor: _cabankAccent,
  brightness: Brightness.dark,
  useMaterial3: true,

  // Background/UI colors
  scaffoldBackgroundColor: _darkBackground,
  cardColor: const Color(0xFF1E1E1E), // Slightly lighter than background for depth


  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),


  appBarTheme: const AppBarTheme(
    color: Colors.black, // True black background
    foregroundColor: Colors.white,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
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

