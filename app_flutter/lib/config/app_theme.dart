import 'package:flutter/material.dart';

class AppTheme {
  static const Color laranja =
      Color(0xFFF97316);

  // =====================================
  // TEMA CLARO
  // =====================================

  static ThemeData lightTheme =
      ThemeData(
    brightness: Brightness.light,

    primaryColor: laranja,

    scaffoldBackgroundColor:
        const Color(0xFFF5F5F5),

    colorScheme:
        ColorScheme.fromSeed(
      seedColor: laranja,
      brightness:
          Brightness.light,
    ),

    appBarTheme:
        const AppBarTheme(
      backgroundColor: laranja,
      foregroundColor:
          Colors.white,
      elevation: 0,
    ),

    inputDecorationTheme:
        InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.all(
          Radius.circular(12),
        ),
      ),
    ),

    cardTheme:
        const CardThemeData(
      color: Colors.white,
    ),
  );

  // =====================================
  // TEMA ESCURO
  // =====================================

  static ThemeData darkTheme =
      ThemeData(
    brightness: Brightness.dark,

    primaryColor: laranja,

    scaffoldBackgroundColor:
        const Color(0xFF121212),

    colorScheme:
        ColorScheme.fromSeed(
      seedColor: laranja,
      brightness:
          Brightness.dark,
    ),

    appBarTheme:
        const AppBarTheme(
      backgroundColor: laranja,
      foregroundColor:
          Colors.white,
      elevation: 0,
    ),

    inputDecorationTheme:
        const InputDecorationTheme(
      filled: true,
      fillColor:
          Color(0xFF1E1E1E),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.all(
          Radius.circular(12),
        ),
      ),
    ),

    cardTheme:
        const CardThemeData(
      color: Color(0xFF1E1E1E),
    ),
  );
}