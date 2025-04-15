import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/themes/app_theme.dart';
import '../../data/services/storage_service.dart';

class ThemeProvider extends GetxController {
  final StorageService _storage;

  ThemeProvider(this._storage);

  // Store the user's preference ('light', 'dark', 'sepia', 'system')
  final _themeSetting = 'system'.obs;
  // Store the actual ThemeMode derived from setting or system
  final _themeMode = ThemeMode.system.obs;
  final _textDirection = TextDirection.ltr.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  ThemeMode get themeMode => _themeMode.value;
  String get themeSetting => _themeSetting.value;
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      return Get.mediaQuery.platformBrightness == Brightness.dark;
    }
    return _themeMode.value == ThemeMode.dark;
  }

  TextDirection get textDirection => _textDirection.value;

  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;
  ThemeData get sepiaTheme => AppTheme.sepiaTheme; // Add sepia theme getter

  // Determines the actual ThemeMode based on the setting
  ThemeMode _calculateThemeMode(String setting) {
    switch (setting) {
      case 'light':
      case 'sepia': // Sepia uses light mode internally
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default: // 'system' or invalid
        return ThemeMode.system;
    }
  }

  // Called by SettingsController to update the theme *setting*
  void changeThemeSetting(String setting) {
    try {
      if (_themeSetting.value == setting) return; // No change needed

      _themeSetting.value = setting;
      _themeMode.value = _calculateThemeMode(setting);

      // Apply the change visually
      // Get.changeThemeMode(_themeMode.value); // This might not be enough if GetMaterialApp is not setup correctly
      Get.changeTheme(currentThemeData); // Force theme data update

      saveThemeSetting(setting); // Save the user's choice
    } catch (e) {
      debugPrint('Error changing theme setting: $e');
    }
  }

  // Keep toggleTheme for potential direct use, but ensure it updates the setting
  void toggleTheme() {
    final newSetting = isDarkMode ? 'light' : 'dark';
    changeThemeSetting(newSetting);
  }

  void updateTextDirection(TextDirection direction) {
    _textDirection.value = direction;
  }

  // Load the user's *setting* ('light', 'dark', 'sepia', 'system')
  Future<void> loadTheme() async {
    try {
      // Read the saved setting, default to 'system'
      final savedSetting = _storage.read<String>('theme') ?? 'system';
      _themeSetting.value = savedSetting;
      _themeMode.value = _calculateThemeMode(savedSetting);

      // Apply the theme mode on load
      Get.changeThemeMode(_themeMode.value);

      debugPrint(
          "Theme loaded - Setting: ${_themeSetting.value}, Mode: ${_themeMode.value}");
    } catch (e) {
      debugPrint('Error loading theme setting: $e');
      _themeSetting.value = 'system';
      _themeMode.value = ThemeMode.system;
      Get.changeThemeMode(ThemeMode.system);
    }
  }

  // Save the user's *setting*
  Future<void> saveThemeSetting(String setting) async {
    try {
      await _storage.write('theme', setting);
      debugPrint("Theme setting saved: $setting");
    } catch (e) {
      debugPrint('Error saving theme setting: $e');
    }
  }

  // Getter to provide the correct ThemeData based on the *setting*
  ThemeData get currentThemeData {
    switch (_themeSetting.value) {
      case 'sepia':
        debugPrint("Applying Sepia Theme");
        return sepiaTheme;
      case 'light':
        debugPrint("Applying Light Theme");
        return lightTheme;
      case 'dark':
        debugPrint("Applying Dark Theme");
        return darkTheme;
      case 'system':
      default:
        // Use system brightness to decide between light/dark
        final brightness = Get.mediaQuery.platformBrightness;
        debugPrint("Applying System Theme (Brightness: $brightness)");
        return brightness == Brightness.dark ? darkTheme : lightTheme;
      // Alternatively, could return lightTheme and let GetMaterialApp handle darkTheme via themeMode
      // return lightTheme;
    }
  }
}
