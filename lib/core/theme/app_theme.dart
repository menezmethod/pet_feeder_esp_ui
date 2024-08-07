import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: Color(0xFF40798C),
    scaffoldBackgroundColor: Color(0xFFCFD7C7),
    colorScheme: ColorScheme(
      primary: Color(0xFF40798C),
      primaryContainer: Color(0xFF70A9A1),
      secondary: Color(0xFF0B2027),
      secondaryContainer: Color(0xFF40798C),
      surface: Color(0xFFF6F1D1),
      background: Color(0xFFCFD7C7),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0B2027)),
      bodyMedium: TextStyle(color: Color(0xFF0B2027)),
    ),
  );
}