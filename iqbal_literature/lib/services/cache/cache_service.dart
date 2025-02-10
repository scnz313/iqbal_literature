import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Fixed import

class CacheService {
  static late SharedPreferences _prefs;
  static const String _analysisPrefix = 'poem_analysis_';
  static const String _timelinePrefix = 'timeline_';
  static const Duration _cacheDuration = Duration(days: 7);

  // Initialize the cache service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Store data with expiration
  static Future<bool> set(String key, dynamic data) async {
    try {
      final cacheEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      
      return await _prefs.setString(key, jsonEncode(cacheEntry));
    } catch (e) {
      debugPrint('❌ Cache write error: $e');
      return false;
    }
  }

  // Get data if not expired
  static dynamic get(String key) {
    try {
      final rawData = _prefs.getString(key);
      if (rawData == null) return null;

      final cacheEntry = jsonDecode(rawData);
      final timestamp = DateTime.parse(cacheEntry['timestamp']);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        _prefs.remove(key); // Clear expired cache
        return null;
      }

      return cacheEntry['data'];
    } catch (e) {
      debugPrint('❌ Cache read error: $e');
      return null;
    }
  }

  // Cache poem analysis
  static Future<bool> cacheAnalysis(String poemId, Map<String, String> analysis) async {
    return await set('${_analysisPrefix}$poemId', analysis);
  }

  // Get cached poem analysis
  static Map<String, String>? getAnalysis(String poemId) {
    final data = get('${_analysisPrefix}$poemId');
    if (data == null) return null;
    
    return Map<String, String>.from(data);
  }

  // Cache timeline data
  static Future<bool> cacheTimeline(String bookId, List<Map<String, dynamic>> timeline) async {
    return await set('${_timelinePrefix}$bookId', timeline);
  }

  // Get cached timeline
  static List<Map<String, dynamic>>? getTimeline(String bookId) {
    final data = get('${_timelinePrefix}$bookId');
    if (data == null) return null;
    
    return List<Map<String, dynamic>>.from(data);
  }

  // Clear specific cache
  static Future<bool> clear(String key) async {
    return await _prefs.remove(key);
  }

  // Clear all cache
  static Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  // Clear expired cache entries
  static Future<void> clearExpired() async {
    try {
      final keys = _prefs.getKeys();
      for (final key in keys) {
        final rawData = _prefs.getString(key);
        if (rawData == null) continue;

        final cacheEntry = jsonDecode(rawData);
        final timestamp = DateTime.parse(cacheEntry['timestamp']);
        
        if (DateTime.now().difference(timestamp) > _cacheDuration) {
          await _prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('❌ Cache cleanup error: $e');
    }
  }

  // Get cache statistics
  static Map<String, dynamic> getStats() {
    try {
      final keys = _prefs.getKeys();
      int analysisCount = 0;
      int timelineCount = 0;
      int expiredCount = 0;

      for (final key in keys) {
        if (key.startsWith(_analysisPrefix)) analysisCount++;
        if (key.startsWith(_timelinePrefix)) timelineCount++;

        final rawData = _prefs.getString(key);
        if (rawData != null) {
          final cacheEntry = jsonDecode(rawData);
          final timestamp = DateTime.parse(cacheEntry['timestamp']);
          if (DateTime.now().difference(timestamp) > _cacheDuration) {
            expiredCount++;
          }
        }
      }

      return {
        'totalEntries': keys.length,
        'analysisEntries': analysisCount,
        'timelineEntries': timelineCount,
        'expiredEntries': expiredCount,
      };
    } catch (e) {
      debugPrint('❌ Cache stats error: $e');
      return {};
    }
  }
}
