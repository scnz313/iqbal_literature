import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/analytics_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../config/providers/theme_provider.dart';
import '../../../config/providers/locale_provider.dart';
import '../../../core/localization/language_constants.dart';
import '../../../config/providers/font_scale_provider.dart';

class SettingsController extends GetxController {
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
  late final ThemeProvider _themeProvider;
  late final LocaleProvider _localeProvider;
  late final FontScaleProvider _fontScaleProvider;

  SettingsController(
    this._storageService,
    this._analyticsService,
  ) {
    _themeProvider = Get.find<ThemeProvider>();
    _localeProvider = Get.find<LocaleProvider>();
    _fontScaleProvider = Get.find<FontScaleProvider>();
  }

  final RxString currentLanguage = 'en'.obs;
  final RxString currentTheme = 'system'.obs;
  final RxString cacheSize = '0.00'.obs;
  String appVersion = '';
  final isNightModeScheduled = false.obs;
  final RxDouble fontScale = 1.0.obs;  // Change to RxDouble

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    getAppVersion();
    _analyticsService.logEvent(
      name: 'screen_view',
      parameters: {'screen': 'Settings'},
    );
  }

  Future<void> loadSettings() async {
    try {
      // Load theme
      final savedTheme = _storageService.read<String>('theme');
      if (savedTheme != null) {
        currentTheme.value = savedTheme;
        _themeProvider.setThemeMode(_getThemeMode(savedTheme));
      }

      // Load language
      final savedLanguage = _storageService.read<String>('language');
      if (savedLanguage != null) {
        currentLanguage.value = savedLanguage;
        _localeProvider.setLocale(Locale(savedLanguage));
      }

      debugPrint('Settings loaded - Theme: ${currentTheme.value}, Language: ${currentLanguage.value}');
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> changeLanguage(String language) async {
    try {
      currentLanguage.value = language;
      await _storageService.write('language', language);
      final locale = LanguageConstants.getLocaleFromLanguageCode(language);
      _localeProvider.setLocale(locale);
      Get.updateLocale(locale);
      
      _analyticsService.logEvent(
        name: 'change_language',
        parameters: {'language': language},
      );
    } catch (e) {
      debugPrint('Error changing language: $e');
      Get.snackbar(
        'error'.tr,
        'Failed to change language',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> changeTheme(String theme) async {
    try {
      currentTheme.value = theme;
      await _storageService.write('theme', theme);
      _themeProvider.setThemeMode(_getThemeMode(theme));
      
      _analyticsService.logEvent(
        name: 'change_theme',
        parameters: {'theme': theme},
      );
    } catch (e) {
      debugPrint('Error changing theme: $e');
    }
  }

  ThemeMode _getThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> calculateCacheSize() async {
    try {
      final size = await _storageService.getCacheSize();
      cacheSize.value = size;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      cacheSize.value = '0.00';
    }
  }

  Future<void> clearCache() async {
    try {
      await _storageService.clearCache();
      await calculateCacheSize();
      
      Get.snackbar(
        'Success',
        'Cache cleared successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      _analyticsService.logEvent(name: 'clear_cache');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      Get.snackbar(
        'Error',
        'Failed to clear cache',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      debugPrint('App version: $appVersion');
    } catch (e) {
      debugPrint('Error getting app version: $e');
      appVersion = AppConstants.appVersion;
    }
  }

  void showAbout() {
    Get.dialog(
      AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: $appVersion'),
            const SizedBox(height: 8),
            const Text('Iqbal Literature App'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> setFontScale(double scale) async {
    try {
      await FontScaleProvider.to.setFontScale(scale);
      _analyticsService.logEvent(
        name: 'change_font_size',
        parameters: {'scale': scale},
      );
    } catch (e) {
      debugPrint('Error saving font scale: $e');
      Get.snackbar(
        'error'.tr,
        'Failed to update font size',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  double get currentFontScale => FontScaleProvider.to.fontScale.value;

  void enableNightModeSchedule(bool value) {
    isNightModeScheduled.value = value;
    // ...implementation...
  }
}
