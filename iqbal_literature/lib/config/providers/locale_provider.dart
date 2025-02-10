import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/localization/language_constants.dart';
import '../../data/services/storage_service.dart'; // Adjust the path as necessary

class LocaleProvider extends GetxController {
  final _locale = const Locale('en', 'US').obs;
  final StorageService _storage;
  
  LocaleProvider(this._storage);
  
  Locale get locale => _locale.value;

  void setLocale(Locale locale) {
    _locale.value = locale;
    Get.updateLocale(locale);
  }

  void changeLanguage(String languageCode) {
    final locale = LanguageConstants.getLocaleFromLanguageCode(languageCode);
    setLocale(locale);
    saveLanguage(languageCode);
  }

  Future<void> loadLanguage() async {
    try {
      final locale = _storage.read('locale') ?? 'en';
      // Set locale logic
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  Future<void> saveLanguage(String languageCode) async {
    await Get.find<StorageService>().write('language', languageCode);
  }

  String getCurrentLanguageName() {
    return LanguageConstants.getLanguageName(locale.languageCode);
  }
}
