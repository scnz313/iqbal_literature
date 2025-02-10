import 'package:flutter/material.dart';

class AppColorSchemes {
  // Light Theme Colors
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1E6F5C),
    onPrimary: Colors.white,
    secondary: Color(0xFF29BB89),
    onSecondary: Colors.white,
    error: Color(0xFFB00020),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF121212),
  );
  
  // Dark Theme Colors
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF29BB89),
    onPrimary: Colors.white,
    secondary: Color(0xFF1E6F5C),
    onSecondary: Colors.white,
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Color(0xFF1E1E1E),
    onSurface: Colors.white,
  );
  
  // Custom Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color disabledColor = Color(0xFF9E9E9E);
}
