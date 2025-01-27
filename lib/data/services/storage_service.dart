import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage storage;
  final SharedPreferences prefs;
  static const String _themeKey = 'theme';
  static const String _languageKey = 'language';

  StorageService({
    required this.storage,
    required this.prefs,
  });

  Future<void> initialize() async {
    try {
      if (!prefs.containsKey('theme_mode')) {
        await prefs.setString('theme_mode', 'system');
      }
      if (!prefs.containsKey('language')) {
        await prefs.setString('language', 'en');
      }
    } catch (e) {
      debugPrint('Error initializing StorageService: $e');
    }
  }

  Future<bool> write<T>(String key, T value) async {
    try {
      if (value == null) return false;
      switch (T) {
        case String: return await prefs.setString(key, value as String);
        case bool: return await prefs.setBool(key, value as bool);
        case int: return await prefs.setInt(key, value as int);
        case double: return await prefs.setDouble(key, value as double);
        case const (List<String>): return await prefs.setStringList(key, value as List<String>);
        default: return false;
      }
    } catch (e) {
      debugPrint('Error writing to storage: $e');
      return false;
    }
  }

  T? read<T>(String key) {
    try {
      return prefs.get(key) as T?;
    } catch (e) {
      debugPrint('Error reading from storage: $e');
      return null;
    }
  }

  Future<bool> delete(String key) => prefs.remove(key);
  Future<bool> clear() => prefs.clear();
  bool containsKey(String key) => prefs.containsKey(key);

  Future<String> getCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      if (!dir.existsSync()) {
        return '0.00';
      }
      
      int total = 0;
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return (total / (1024 * 1024)).toStringAsFixed(2);
    } catch (e) {
      debugPrint('StorageService: Error getting cache size: $e');
      return '0.00';
    }
  }

  Future<void> clearCache() async {
    try {
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    } catch (e) {
      debugPrint('StorageService: Error clearing cache: $e');
    }
  }

  Future<bool> saveTheme(String theme) async {
    debugPrint('StorageService: Saving theme: $theme');
    return await write<String>(_themeKey, theme);
  }

  String getTheme() {
    try {
      return prefs.getString(_themeKey) ?? 'system';
    } catch (e) {
      debugPrint('StorageService: Error getting theme: $e');
      return 'system';
    }
  }

  Future<bool> saveLanguage(String language) async {
    debugPrint('StorageService: Saving language: $language');
    return await write<String>(_languageKey, language);
  }

  String getLanguage() {
    try {
      return prefs.getString(_languageKey) ?? 'en';
    } catch (e) {
      debugPrint('StorageService: Error getting language: $e');
      return 'en';
    }
  }

  Future<void> reload() async {
    try {
      await prefs.reload();
    } catch (e) {
      debugPrint('StorageService: Error reloading preferences: $e');
    }
  }
}
