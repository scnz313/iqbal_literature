import 'package:firebase_analytics/firebase_analytics.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;
  
  AnalyticsService(this._analytics);

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!AppConstants.enableAnalytics) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Screen view logging error: $e');
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!AppConstants.enableAnalytics) return;

    try {
      // Convert boolean values to strings
      final convertedParams = parameters?.map((key, value) {
        if (value is bool) {
          return MapEntry(key, value.toString());
        }
        return MapEntry(key, value);
      });

      await _analytics.logEvent(
        name: name,
        parameters: convertedParams,
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logBookView(int bookId, String bookTitle) async {
    await logEvent(
      name: 'book_view',
      parameters: {
        'book_id': bookId,
        'book_title': bookTitle,
      },
    );
  }

  Future<void> logPoemView(int poemId, String poemTitle) async {
    await logEvent(
      name: 'poem_view',
      parameters: {
        'poem_id': poemId,
        'poem_title': poemTitle,
      },
    );
  }

  Future<void> logSearch(String query, String category, int resultCount) async {
    await logEvent(
      name: 'search',
      parameters: {
        'query': query,
        'category': category,
        'result_count': resultCount,
      },
    );
  }

  Future<void> logError(String errorMessage, String stackTrace) async {
    await logEvent(
      name: 'error',
      parameters: {
        'error_message': errorMessage,
        'stack_trace': stackTrace,
      },
    );
  }

  Future<void> setUserProperties({
    String? userId,
    String? userLanguage,
    String? userTheme,
  }) async {
    if (!AppConstants.enableAnalytics) return;

    if (userId != null) {
      await _analytics.setUserId(id: userId);
    }
    if (userLanguage != null) {
      await _analytics.setUserProperty(
        name: 'user_language',
        value: userLanguage,
      );
    }
    if (userTheme != null) {
      await _analytics.setUserProperty(
        name: 'user_theme',
        value: userTheme,
      );
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('User property setting error: $e');
    }
  }
}
