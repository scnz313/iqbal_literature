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

  // Sepia Theme Colors
  static const ColorScheme sepiaColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF8C6239), // Muted bronze/rich brown
    onPrimary: Color(0xFFF5EAD6), // Match background
    secondary: Color(0xFFA57D52), // Slightly lighter brown accent
    onSecondary: Color(0xFFF5EAD6), // Match background
    error: Color(0xFFB00020), // Standard error red
    onError: Colors.white,
    surface: Color(0xFFF5EAD6), // Light Beige / Paper-like tone
    onSurface: Color(0xFF4B3A2D), // Dark Brown text
    // Optional: Define other colors like background, surfaceVariant etc. if needed
    // background: Color(0xFFF5EAD6), // Explicitly set background if needed
    // onBackground: Color(0xFF4B3A2D),
    // surfaceVariant: Color(0xFFEAE0D0), // Slightly different variant for cards/dialogs?
    // outline: Color(0xFFD6C5AE), // Soft divider/border color
  );

  // Custom Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color dividerColor =
      Color(0xFFD6C5AE); // Use Sepia divider color suggestion
  static const Color disabledColor = Color(0xFF9E9E9E);
}
