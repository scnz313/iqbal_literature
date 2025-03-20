import 'package:flutter/material.dart';

/// MediaQuery extensions
extension MediaQueryExtension on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is a tablet (shortestSide >= 600)
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;

  /// Check if device is a large tablet (shortestSide >= 900)
  bool get isLargeTablet => MediaQuery.of(this).size.shortestSide >= 900;

  /// Get the width fraction of the screen (0.5 = 50% of screen width)
  double widthFraction(double fraction) => screenWidth * fraction;

  /// Get the height fraction of the screen (0.5 = 50% of screen height)
  double heightFraction(double fraction) => screenHeight * fraction;
}
