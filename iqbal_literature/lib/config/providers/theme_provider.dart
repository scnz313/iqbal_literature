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
      final newMode = _calculateThemeMode(setting);
      if (_themeMode.value != newMode) {
        _themeMode.value = newMode;
        // Explicitly change theme mode if it differs
        Get.changeThemeMode(newMode);
        debugPrint("ThemeProvider: Changed ThemeMode to $newMode");
      }

      // Apply the specific theme data
      // Get.changeTheme(currentThemeData); // Might be redundant if changeThemeMode works
      // Let's rely on GetMaterialApp reacting to themeMode change first.
      // If needed, we can re-add Get.changeTheme(currentThemeData)

      saveThemeSetting(setting); // Save the user's choice
      debugPrint("ThemeProvider: Set theme setting to '$setting'");

      // Force update GetMaterialApp theme properties by triggering Obx rebuild
      update(); // Notify listeners of ThemeProvider
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
        debugPrint("Providing Sepia Theme");
        return sepiaTheme;
      case 'dark':
        debugPrint("Providing Dark Theme");
        return darkTheme;
      case 'light':
      case 'system': // For system, provide the light theme; GetMaterialApp handles dark mode.
      default:
        debugPrint("Providing Light Theme (System/Light setting)");
        return lightTheme;
    }
  }
}
