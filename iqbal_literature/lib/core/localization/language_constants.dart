import 'package:flutter/material.dart';

class LanguageConstants {
  static const Locale englishLocale = Locale('en', 'US');
  static const Locale urduLocale = Locale('ur', 'PK');
  
  static const List<Locale> supportedLocales = [
    englishLocale,
    urduLocale,
  ];
  
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ur': 'اردو',
  };
  
  static Locale getLocaleFromLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'ur':
        return urduLocale;
      case 'en':
      default:
        return englishLocale;
    }
  }
  
  static String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
}
