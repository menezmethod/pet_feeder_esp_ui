import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF40798C),
    scaffoldBackgroundColor: const Color(0xFFCFD7C7),
    colorScheme: const ColorScheme(
      primary: Color(0xFF40798C),
      primaryContainer: Color(0xFF70A9A1),
      secondary: Color(0xFF0B2027),
      secondaryContainer: Color(0xFF40798C),
      surface: Color(0xFFF6F1D1),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0B2027)),
      bodyMedium: TextStyle(color: Color(0xFF0B2027)),
    ),
  );

  // Same brand hue family as lightTheme (teal-blue primary, dark-navy
  // secondary), inverted for dark surfaces -- not the stock ThemeData.dark(),
  // which carried none of this app's actual branding.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6FA8BB),
    scaffoldBackgroundColor: const Color(0xFF0B2027),
    colorScheme: const ColorScheme(
      primary: Color(0xFF6FA8BB),
      primaryContainer: Color(0xFF2F5A66),
      secondary: Color(0xFFCFD7C7),
      secondaryContainer: Color(0xFF40798C),
      surface: Color(0xFF14232A),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF06141A),
      onSecondary: Color(0xFF06141A),
      onSurface: Color(0xFFE6EDEE),
      onError: Colors.black,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE6EDEE)),
      bodyMedium: TextStyle(color: Color(0xFFE6EDEE)),
    ),
  );
}
