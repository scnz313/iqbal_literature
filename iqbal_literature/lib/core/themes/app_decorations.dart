import 'package:flutter/material.dart';
import 'color_schemes.dart';

class AppDecorations {
  // Card Decorations
  static final RoundedRectangleBorder defaultCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12.0),
  );

  static const EdgeInsets defaultCardMargin = EdgeInsets.all(8.0);

  static final BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4.0,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Button Styles
  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // Input Decorations
  static InputDecoration textFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: AppColorSchemes.lightColorScheme.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: AppColorSchemes.lightColorScheme.primary,
          width: 2.0,
        ),
      ),
    );
  }

  // Container Decorations
  static final BoxDecoration roundedContainerDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12.0),
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4.0,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Snackbar Shape
  static final RoundedRectangleBorder defaultSnackBarShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8.0),
  );

  // Dialog Decorations
  static final RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16.0),
  );

  // Bottom Sheet Decoration
  static final BoxDecoration bottomSheetDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(20),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  );
}
