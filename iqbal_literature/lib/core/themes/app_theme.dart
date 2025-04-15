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
    cardTheme: CardThemeData(
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
    dividerColor: AppColorSchemes.dividerColor,
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
    cardTheme: CardThemeData(
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
    dividerColor: AppColorSchemes.dividerColor,
  );

  static final ThemeData sepiaTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: AppColorSchemes.sepiaColorScheme,
    textTheme: AppTextStyles.textTheme.apply(
      bodyColor: AppColorSchemes.sepiaColorScheme.onSurface,
      displayColor: AppColorSchemes.sepiaColorScheme.onSurface,
    ),
    scaffoldBackgroundColor: AppColorSchemes.sepiaColorScheme.surface,
    appBarTheme: AppBarTheme(
      elevation: 1,
      centerTitle: true,
      backgroundColor: AppColorSchemes.sepiaColorScheme.primary,
      foregroundColor: AppColorSchemes.sepiaColorScheme.onPrimary,
      titleTextStyle: AppTextStyles.textTheme.titleLarge?.copyWith(
        color: AppColorSchemes.sepiaColorScheme.onPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: AppDecorations.defaultCardShape,
      margin: AppDecorations.defaultCardMargin,
      color: AppColorSchemes.sepiaColorScheme.surface,
      shadowColor: AppColorSchemes.sepiaColorScheme.primary.withOpacity(0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppDecorations.elevatedButtonStyle.copyWith(
        backgroundColor:
            MaterialStateProperty.all(AppColorSchemes.sepiaColorScheme.primary),
        foregroundColor: MaterialStateProperty.all(
            AppColorSchemes.sepiaColorScheme.onPrimary),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: AppDecorations.defaultSnackBarShape,
      backgroundColor: AppColorSchemes.sepiaColorScheme.onSurface,
      contentTextStyle:
          TextStyle(color: AppColorSchemes.sepiaColorScheme.surface),
    ),
    dividerColor: AppColorSchemes.dividerColor,
  );
}
