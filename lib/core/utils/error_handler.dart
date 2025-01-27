import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../constants/app_constants.dart';

class ErrorHandler {
  static Future<void> handleError(dynamic error, StackTrace stackTrace) async {
    try {
      if (AppConstants.enableLogging) {
        debugPrint('Error: $error');
        debugPrint('StackTrace: $stackTrace');
      }

      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'App Error',
          fatal: false,
        );
      }
    } catch (e) {
      debugPrint('Error handling failed: $e');
    }
  }

  static Future<void> handleFatalError(dynamic error, StackTrace stackTrace) async {
    try {
      debugPrint('Fatal Error: $error');
      debugPrint('StackTrace: $stackTrace');

      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'Fatal Error',
          fatal: true,
        );
      }
    } catch (e) {
      debugPrint('Fatal error handling failed: $e');
    }
  }

  static String getUserFriendlyError(dynamic error) {
    if (error is Exception) {
      return _handleException(error);
    }
    return 'An unexpected error occurred. Please try again.';
  }

  static String _handleException(Exception exception) {
    switch (exception.runtimeType) {
      case TimeoutException:
        return 'Connection timed out. Please check your internet connection.';
      case NetworkException:
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
}