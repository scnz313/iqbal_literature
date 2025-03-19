import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/localization/language_constants.dart';
import '../../data/services/storage_service.dart'; // Adjust the path as necessary

class LocaleProvider extends GetxController {
  final Rx<Locale> locale = Rx<Locale>(const Locale('en', 'US'));
  final StorageService _storage;

  LocaleProvider(this._storage);

  // For compatibility with the existing code
  Locale get currentLocale => locale.value;

  void setLocale(Locale newLocale) {
    locale.value = newLocale;
    Get.updateLocale(newLocale);
  }

  void changeLanguage(String languageCode) {
    final newLocale = LanguageConstants.getLocaleFromLanguageCode(languageCode);
    setLocale(newLocale);
    saveLanguage(languageCode);
  }

  Future<void> loadLanguage() async {
    try {
      final languageCode = _storage.read<String>('language') ?? 'en';
      final newLocale =
          LanguageConstants.getLocaleFromLanguageCode(languageCode);
      setLocale(newLocale);
      debugPrint('📱 Loaded language: ${newLocale.languageCode}');
    } catch (e) {
      debugPrint('❌ Error loading locale: $e');
      // Default to English on error
      setLocale(const Locale('en', 'US'));
    }
  }

  Future<void> saveLanguage(String languageCode) async {
    try {
      await _storage.write('language', languageCode);
      debugPrint('💾 Saved language preference: $languageCode');
    } catch (e) {
      debugPrint('❌ Error saving language: $e');
    }
  }

  String getCurrentLanguageName() {
    return LanguageConstants.getLanguageName(locale.value.languageCode);
  }

  // For enabling reactive language switching throughout the app
  static LocaleProvider get to => Get.find<LocaleProvider>();
}
