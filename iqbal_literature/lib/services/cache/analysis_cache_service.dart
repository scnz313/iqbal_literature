import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class AnalysisCacheService {
  static const String _boxName = 'analysis_cache';
  static const String _wordAnalysisPrefix = 'word_analysis_';
  static const String _poemAnalysisPrefix = 'poem_analysis_';
  static const String _timelinePrefix = 'timeline_';
  static const String _usageStatsKey = 'api_usage_stats';
  static const String _historyKey = 'analysis_history';
  static const Duration _cacheDuration = Duration(days: 30);

  // Rate limiting constants
  static const int _maxDailyRequests = 50;

  late Box _cacheBox;
  bool _isInitialized = false;

  // Public initialization method for compatibility
  Future<void> init() async {
    await _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _cacheBox = await Hive.openBox(_boxName);
    _isInitialized = true;
  }

  Future<bool> canMakeRequest() async {
    await _initialize();
    final stats = await _getUsageStats();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Reset count if it's a new day
    if (stats['date'] != today) {
      await _resetDailyCount();
      return true;
    }

    return stats['count'] < _maxDailyRequests;
  }

  Future<void> incrementRequestCount() async {
    await _initialize();
    final stats = await _getUsageStats();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Reset count if it's a new day
    if (stats['date'] != today) {
      await _resetDailyCount();
      return;
    }

    stats['count'] = (stats['count'] as int) + 1;
    await _cacheBox.put(_usageStatsKey, stats);
  }

  Future<Map<String, dynamic>> _getUsageStats() async {
    await _initialize();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final stats = _cacheBox.get(_usageStatsKey);
    if (stats == null) {
      final newStats = {
        'date': today,
        'count': 0,
      };
      await _cacheBox.put(_usageStatsKey, newStats);
      return newStats;
    }

    return Map<String, dynamic>.from(stats);
  }

  Future<void> _resetDailyCount() async {
    await _initialize();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _cacheBox.put(_usageStatsKey, {
      'date': today,
      'count': 0,
    });
  }

  Future<Map<String, dynamic>?> getWordAnalysis(String word) async {
    await _initialize();
    final key = '${_wordAnalysisPrefix}${word.toLowerCase()}';
    final cachedData = _cacheBox.get(key);

    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(cachedData);

        // Check if cache is still valid
        if (data.containsKey('timestamp')) {
          final timestamp = DateTime.parse(data['timestamp']);
          if (DateTime.now().difference(timestamp) < _cacheDuration) {
            debugPrint('📦 Using cached word analysis for "$word"');
            // Add to history
            await _addToHistory(word, 'word', data['timestamp']);

            // Make sure we return a proper Map<String, dynamic>
            if (data['analysis'] is Map) {
              return Map<String, dynamic>.from(data['analysis']);
            } else {
              debugPrint('⚠️ Cached word analysis has invalid format');
              return null;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error retrieving cached word analysis: $e');
        return null;
      }
    }

    return null;
  }

  Future<void> cacheWordAnalysis(
      String word, Map<String, dynamic> analysis) async {
    await _initialize();
    final key = '${_wordAnalysisPrefix}${word.toLowerCase()}';
    final timestamp = DateTime.now().toIso8601String();

    final data = {
      'analysis': analysis,
      'timestamp': timestamp,
    };

    await _cacheBox.put(key, data);
    // Add to history
    await _addToHistory(word, 'word', timestamp);
    debugPrint('📦 Cached word analysis for "$word"');
  }

  Future<Map<String, dynamic>?> getPoemAnalysis(int poemId) async {
    await _initialize();
    final key = '${_poemAnalysisPrefix}$poemId';
    final cachedData = _cacheBox.get(key);

    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(cachedData);

        // Check if cache is still valid
        if (data.containsKey('timestamp')) {
          final timestamp = DateTime.parse(data['timestamp']);
          if (DateTime.now().difference(timestamp) < _cacheDuration) {
            debugPrint('📦 Using cached poem analysis for poem #$poemId');
            // Add to history
            await _addToHistory('Poem #$poemId', 'poem', data['timestamp']);

            // Make sure we return a proper Map<String, dynamic>
            if (data['analysis'] is Map) {
              return Map<String, dynamic>.from(data['analysis']);
            } else {
              debugPrint('⚠️ Cached poem analysis has invalid format');
              return null;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error retrieving cached poem analysis: $e');
        return null;
      }
    }

    return null;
  }

  Future<void> cachePoemAnalysis(
      int poemId, Map<String, dynamic> analysis) async {
    await _initialize();
    final key = '${_poemAnalysisPrefix}$poemId';
    final timestamp = DateTime.now().toIso8601String();

    final data = {
      'analysis': analysis,
      'timestamp': timestamp,
    };

    await _cacheBox.put(key, data);
    // Add to history
    await _addToHistory('Poem #$poemId', 'poem', timestamp);
    debugPrint('📦 Cached poem analysis for poem #$poemId');
  }

  Future<List<Map<String, dynamic>>?> getTimelineEvents(int bookId) async {
    await _initialize();
    final key = '${_timelinePrefix}$bookId';
    final cachedData = _cacheBox.get(key);

    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(cachedData);

        // Check if cache is still valid
        if (data.containsKey('timestamp')) {
          final timestamp = DateTime.parse(data['timestamp']);
          if (DateTime.now().difference(timestamp) < _cacheDuration) {
            debugPrint('📦 Using cached timeline for book #$bookId');
            // Add to history
            await _addToHistory(
                'Book #$bookId Timeline', 'timeline', data['timestamp']);

            // Make sure we return a proper List<Map<String, dynamic>>
            if (data['timeline'] is List) {
              return (data['timeline'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            } else {
              debugPrint('⚠️ Cached timeline has invalid format');
              return null;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error retrieving cached timeline: $e');
        return null;
      }
    }

    return null;
  }

  Future<void> cacheTimelineEvents(
      int bookId, List<Map<String, dynamic>> timeline) async {
    await _initialize();
    final key = '${_timelinePrefix}$bookId';
    final timestamp = DateTime.now().toIso8601String();

    final data = {
      'timeline': timeline,
      'timestamp': timestamp,
    };

    await _cacheBox.put(key, data);
    // Add to history
    await _addToHistory('Book #$bookId Timeline', 'timeline', timestamp);
    debugPrint('📦 Cached timeline for book #$bookId');
  }

  Future<void> _addToHistory(String item, String type, String timestamp) async {
    await _initialize();
    final history = _cacheBox.get(_historyKey) ?? [];
    final historyList = List<Map<String, dynamic>>.from(history);

    // Add to beginning of list
    historyList.insert(0, {
      'item': item,
      'type': type,
      'timestamp': timestamp,
    });

    // Keep only the latest 100 items
    if (historyList.length > 100) {
      historyList.removeRange(100, historyList.length);
    }

    await _cacheBox.put(_historyKey, historyList);
  }

  Future<List<Map<String, dynamic>>> getAnalysisHistory() async {
    await _initialize();
    final history = _cacheBox.get(_historyKey) ?? [];
    return List<Map<String, dynamic>>.from(history);
  }

  Future<void> clearCache() async {
    await _initialize();

    // Clear everything except usage stats
    final keys = _cacheBox.keys.where((key) => key != _usageStatsKey).toList();
    for (final key in keys) {
      await _cacheBox.delete(key);
    }

    debugPrint('🧹 Analysis cache cleared');
  }
}
