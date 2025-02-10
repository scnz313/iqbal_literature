import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../services/api/gemini_api.dart';
import '../../../services/api/deepseek_api_client.dart';
import '../models/timeline_event.dart';
import '../data/timeline_data.dart';

class HistoricalContextController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<TimelineEvent> timelineEvents = <TimelineEvent>[].obs;
  final RxString error = ''.obs;
  final DeepSeekApiClient _deepSeekClient = DeepSeekApiClient();

  Future<void> loadTimelineData(String bookName, {String? timePeriod}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final events = await GeminiAPI.getTimelineEvents(bookName, timePeriod);
      
      if (events.isEmpty) {
        error.value = 'No timeline events available';
        return;
      }

      timelineEvents.value = events
          .map((e) => TimelineEvent.fromMap(e))
          .toList();

    } catch (e) {
      debugPrint('⚠️ Timeline error: $e');
      // Load default timeline on error
      timelineEvents.value = defaultTimelineEvents;
      error.value = 'Using default timeline data';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, String>> getHistoricalContext(String title, [String? content]) async {
    try {
      isLoading.value = true;
      error.value = '';

      try {
        debugPrint('📝 Requesting historical context from Gemini...');
        final result = await GeminiAPI.getHistoricalContext(title, content ?? '');
        if (_isValidHistoricalContext(result)) {
          return result;
        }
      } catch (e) {
        debugPrint('⚠️ Gemini failed: $e');
        
        // Try DeepSeek as fallback
        try {
          debugPrint('📝 Falling back to DeepSeek...');
          final result = await _deepSeekClient.getHistoricalContext(title, content);
          final parsedResult = _parseHistoricalContext(result);
          if (_isValidHistoricalContext(parsedResult)) {
            return parsedResult;
          }
        } catch (e) {
          debugPrint('❌ DeepSeek failed: $e');
        }
      }

      return _getDefaultHistoricalContext();
    } catch (e) {
      error.value = 'Failed to load historical context: $e';
      return _getDefaultHistoricalContext();
    } finally {
      isLoading.value = false;
    }
  }

  bool _isValidHistoricalContext(Map<String, String> context) {
    return context.values.every((value) => 
      value.isNotEmpty && value != 'Not available');
  }

  String _extractSection(List<String> sections, String header) {
    try {
      final section = sections.firstWhere(
        (s) => s.trim().startsWith(header),
        orElse: () => '',
      );
      return section
          .replaceFirst(header, '')
          .trim()
          .replaceAll(RegExp(r'[^\x00-\x7F\s.,!?()-]'), ''); // Keep only basic characters
    } catch (e) {
      return 'Not available';
    }
  }

  List<Map<String, dynamic>> _getDefaultTimelineEvents() {
    return [
      {
        'year': '1915',
        'title': 'Writing of Asrar-e-Khudi',
        'description': 'Iqbal composes his first Persian masterpiece.',
        'significance': 'Introduces his philosophy of self.',
      },
      {
        'year': '1924',
        'title': 'Bang-e-Dara Publication',
        'description': 'Collection of Urdu poems published.',
        'significance': 'Major contribution to Urdu literature.',
      },
    ];
  }

  Map<String, String> _getDefaultHistoricalContext() {
    return {
      'year': 'Unknown',
      'historicalContext': 'Historical context information is currently unavailable.',
      'significance': 'Please try again later.',
    };
  }

  Map<String, String> _parseHistoricalContext(String response) {
    try {
      final sections = response.split('\n\n');
      return {
        'year': _extractSection(sections, 'Year:'),
        'historicalContext': _extractSection(sections, 'Historical Context:'),
        'significance': _extractSection(sections, 'Significance:'),
      };
    } catch (e) {
      debugPrint('Error parsing historical context: $e');
      return _getDefaultHistoricalContext();
    }
  }
}
