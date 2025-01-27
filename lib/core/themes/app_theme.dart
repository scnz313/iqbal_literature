import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'text_styles.dart';
import 'app_decorations.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: AppColorSchemes.lightColorScheme,
    textTheme: AppTextStyles.textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColorSchemes.lightColorScheme.primary,
      foregroundColor: AppColorSchemes.lightColorScheme.onPrimary,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: AppDecorations.defaultCardShape,
      margin: AppDecorations.defaultCardMargin,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppDecorations.elevatedButtonStyle,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: AppDecorations.defaultSnackBarShape,
    ),
  );
  
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    useMaterial3: true,
    colorScheme: AppColorSchemes.darkColorScheme,
    textTheme: AppTextStyles.textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColorSchemes.darkColorScheme.primary,
      foregroundColor: AppColorSchemes.darkColorScheme.onPrimary,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: AppDecorations.defaultCardShape,
      margin: AppDecorations.defaultCardMargin,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppDecorations.elevatedButtonStyle,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: AppDecorations.defaultSnackBarShape,
    ),
  );
}
