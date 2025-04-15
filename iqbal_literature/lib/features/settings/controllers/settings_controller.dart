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
  final RxDouble fontScale = 1.0.obs; // Change to RxDouble
  final nightModeStartTime = TimeOfDay(hour: 20, minute: 0).obs;
  final nightModeEndTime = TimeOfDay(hour: 6, minute: 0).obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    getAppVersion();
    _loadNightModeSchedule();
    _analyticsService.logEvent(
      name: 'screen_view',
      parameters: {'screen': 'Settings'},
    );
  }

  Future<void> loadSettings() async {
    try {
      // Load theme setting
      final savedTheme = _storageService.read<String>('theme') ?? 'system';
      if (currentTheme.value != savedTheme) {
        // Check if update is needed
        currentTheme.value = savedTheme;
      }
      // No need to call themeProvider here, its init/loadTheme handles it
      // Removed: _themeProvider.setThemeMode(_getThemeMode(savedTheme));

      // Load language
      final savedLanguage = _storageService.read<String>('language');
      if (savedLanguage != null) {
        currentLanguage.value = savedLanguage;
        _localeProvider.setLocale(Locale(savedLanguage));
      }

      debugPrint(
          'Settings loaded - Theme: ${currentTheme.value}, Language: ${currentLanguage.value}');
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> changeLanguage(String language) async {
    try {
      currentLanguage.value = language;
      await _storageService.write('language', language);

      // Update the locale through the provider
      _localeProvider.changeLanguage(language);

      _analyticsService.logEvent(
        name: 'change_language',
        parameters: {'language': language},
      );

      // Show confirmation to user
      Get.snackbar(
        'success'.tr,
        'language_changed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error changing language: $e');
      Get.snackbar(
        'error'.tr,
        'Failed to change language'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> changeTheme(String theme) async {
    try {
      if (currentTheme.value == theme) return;

      currentTheme.value = theme;
      _themeProvider.changeThemeSetting(theme);

      _analyticsService.logEvent(
        name: 'change_theme',
        parameters: {'theme': theme},
      );
      debugPrint("SettingsController: Called changeThemeSetting with '$theme'");
    } catch (e) {
      debugPrint('Error changing theme in SettingsController: $e');
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
        title: Text('about'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'version'.tr}: $appVersion'),
            const SizedBox(height: 8),
            Text('about'.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
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

  void _loadNightModeSchedule() {
    isNightModeScheduled.value =
        _storageService.read<bool>('night_mode_scheduled') ?? false;
    final startHour = _storageService.read<int>('night_mode_start_hour') ?? 20;
    final startMinute =
        _storageService.read<int>('night_mode_start_minute') ?? 0;
    final endHour = _storageService.read<int>('night_mode_end_hour') ?? 6;
    final endMinute = _storageService.read<int>('night_mode_end_minute') ?? 0;

    nightModeStartTime.value = TimeOfDay(hour: startHour, minute: startMinute);
    nightModeEndTime.value = TimeOfDay(hour: endHour, minute: endMinute);

    if (isNightModeScheduled.value) {
      _checkAndApplyNightMode();
    }
  }

  Future<void> enableNightModeSchedule(bool value) async {
    isNightModeScheduled.value = value;
    await _storageService.write('night_mode_scheduled', value);

    if (value) {
      _checkAndApplyNightMode();
    } else {
      // Revert to system theme when disabled
      changeTheme('system');
    }
  }

  Future<void> setNightModeStartTime(TimeOfDay time) async {
    nightModeStartTime.value = time;
    await _storageService.write('night_mode_start_hour', time.hour);
    await _storageService.write('night_mode_start_minute', time.minute);
    if (isNightModeScheduled.value) {
      _checkAndApplyNightMode();
    }
  }

  Future<void> setNightModeEndTime(TimeOfDay time) async {
    nightModeEndTime.value = time;
    await _storageService.write('night_mode_end_hour', time.hour);
    await _storageService.write('night_mode_end_minute', time.minute);
    if (isNightModeScheduled.value) {
      _checkAndApplyNightMode();
    }
  }

  void _checkAndApplyNightMode() {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes =
        nightModeStartTime.value.hour * 60 + nightModeStartTime.value.minute;
    final endMinutes =
        nightModeEndTime.value.hour * 60 + nightModeEndTime.value.minute;

    bool shouldBeDark;
    if (startMinutes <= endMinutes) {
      shouldBeDark =
          currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      shouldBeDark =
          currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    changeTheme(shouldBeDark ? 'dark' : 'light');
  }
}
