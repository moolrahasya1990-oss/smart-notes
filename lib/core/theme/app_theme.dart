import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff1e3a8a), // Navy seed
      brightness: Brightness.light,
      primary: const Color(0xff1e3a8a),
      onPrimary: Colors.white,
      secondary: const Color(0xff4f46e5),
      background: const Color(0xfff8fafc), // Warm white
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xfff8fafc),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffe2e8f0), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xff0f172a),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xff1e3a8a),
      foregroundColor: Colors.white,
      elevation: 3,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff1e3a8a),
      brightness: Brightness.dark,
      primary: const Color(0xff60a5fa), // Lighter blue for dark mode
      onPrimary: const Color(0xff0f172a),
      secondary: const Color(0xff818cf8),
      background: const Color(0xff090d16), // Dark slate
      surface: const Color(0xff151e2e), // Charcoal cards
    ),
    scaffoldBackgroundColor: const Color(0xff090d16),
    cardTheme: CardTheme(
      color: const Color(0xff151e2e),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xff1e293b), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xfff8fafc),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xff60a5fa),
      foregroundColor: Color(0xff0f172a),
      elevation: 2,
    ),
  );

  // Hex color list for note background customization
  static const List<int> noteColors = [
    0x00ffffff, // Default transparent/background
    0xfffecaca, // Red
    0xfffed7aa, // Orange
    0xfffef08a, // Yellow
    0xffbbf7d0, // Green
    0xff99f6e4, // Teal
    0xffbfdbfe, // Blue
    0xffe9d5ff, // Purple
    0xfffbcfe8, // Pink
  ];
}
