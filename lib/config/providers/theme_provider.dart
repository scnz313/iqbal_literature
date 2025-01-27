import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/themes/app_theme.dart';
import '../../data/services/storage_service.dart';

class ThemeProvider extends GetxController {
  final StorageService _storage;
  
  ThemeProvider(this._storage);

  final _themeMode = ThemeMode.system.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }
  
  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  void setThemeMode(ThemeMode mode) {
    try {
      _themeMode.value = mode;
      Get.changeThemeMode(mode);
      saveTheme(mode);
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  void toggleTheme() {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }

  Future<void> loadTheme() async {
    try {
      final themeMode = _storage.read('theme_mode') ?? 'system';
      switch (themeMode) {
        case 'light':
          _themeMode.value = ThemeMode.light;
          break;
        case 'dark':
          _themeMode.value = ThemeMode.dark;
          break;
        default:
          _themeMode.value = ThemeMode.system;
      }
      Get.changeThemeMode(_themeMode.value);
    } catch (e) {
      debugPrint('Error loading theme: $e');
      _themeMode.value = ThemeMode.system;
    }
  }

  Future<void> saveTheme(ThemeMode mode) async {
    try {
      final themeString = mode == ThemeMode.light ? 'light' : 
                         mode == ThemeMode.dark ? 'dark' : 'system';
      await _storage.write('theme', themeString);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
}
