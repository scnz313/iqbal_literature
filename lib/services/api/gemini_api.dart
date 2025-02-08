import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service class for interacting with Google's Gemini API
class GeminiAPI {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent';
  static String? _apiKey;

  /// Configure the API key for Gemini
  static void configure(String apiKey) {
    _apiKey = apiKey;
  }

  /// Check if API is configured
  static bool get isConfigured => _apiKey != null;

  /// Generate content using Gemini API
  static Future<String> generateContent({
    required String prompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API not configured. Call configure() first.');
    }

    try {
      debugPrint('🤖 Sending request to Gemini API...');

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
            'topP': 1,
            'topK': 40,
          }
        }),
      );

      debugPrint('📡 Gemini Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (content == null) {
          throw Exception('Invalid response format from Gemini API');
        }

        return content.toString();
      }

      throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');

    } catch (e) {
      debugPrint('❌ Gemini API Error: $e');
      rethrow;
    }
  }

  /// Generate poem analysis using specific prompt format
  static Future<Map<String, String>> analyzePoemContent(String text) async {
    try {
      final prompt = '''Analyze this poem and provide clear sections:
$text

Format response EXACTLY as follows (keep the exact section headers):
SUMMARY:
[2-3 sentences summarizing the poem]

THEMES:
• [Theme 1]
• [Theme 2]
• [Theme 3]

HISTORICAL CONTEXT:
[Brief historical background]

ANALYSIS:
[Literary analysis]''';

      final response = await generateContent(
        prompt: prompt,
        temperature: 0.7,
        maxTokens: 1000,
      );

      debugPrint('📝 Raw Gemini Response: $response');

      // Clean markdown formatting and normalize sections
      final cleanedResponse = response
          .replaceAll('**', '')
          .replaceAll('*', '')
          .trim();

      final Map<String, String> result = {};
      var currentSection = '';
      var sectionContent = StringBuffer();

      final lines = cleanedResponse.split('\n');
      for (var line in lines) {
        line = line.trim();
        
        if (line.isEmpty) {
          if (currentSection.isNotEmpty && sectionContent.isNotEmpty) {
            result[currentSection] = sectionContent.toString().trim();
            sectionContent.clear();
          }
          continue;
        }

        if (line.startsWith('SUMMARY:')) {
          currentSection = 'summary';
          continue;
        } else if (line.startsWith('THEMES:')) {
          currentSection = 'themes';
          continue;
        } else if (line.startsWith('HISTORICAL CONTEXT:')) {
          currentSection = 'context';
          continue;
        } else if (line.startsWith('ANALYSIS:')) {
          currentSection = 'analysis';
          continue;
        }

        if (currentSection.isNotEmpty) {
          if (sectionContent.isNotEmpty) {
            sectionContent.write('\n');
          }
          sectionContent.write(line);
        }
      }

      // Add the last section
      if (currentSection.isNotEmpty && sectionContent.isNotEmpty) {
        result[currentSection] = sectionContent.toString().trim();
      }

      debugPrint('📊 Parsed sections: ${result.keys.join(', ')}');
      for (var entry in result.entries) {
        debugPrint('${entry.key}: ${entry.value.substring(0, min(50, entry.value.length))}...');
      }

      if (!_isValidAnalysis(result)) {
        throw Exception('Invalid response format - missing sections');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Gemini analysis error: $e');
      rethrow;
    }
  }

  static void _addSectionContent(Map<String, String> result, String section, String content) {
    final cleaned = content.trim();
    if (cleaned.isNotEmpty) {
      result[section] = cleaned;
    }
  }

  static void _addSection(Map<String, String> result, String section, String content) {
    content = content.trim();
    if (content.isNotEmpty) {
      result[section] = content;
    }
  }

  static List<String> _getMissingSections(Map<String, String> analysis) {
    final requiredSections = ['summary', 'themes', 'context', 'analysis'];
    return requiredSections.where((section) => 
      !analysis.containsKey(section) || 
      analysis[section]?.isEmpty == true
    ).toList();
  }

  static bool _isValidAnalysis(Map<String, String> analysis) {
    final requiredSections = ['summary', 'themes', 'context', 'analysis'];
    final isValid = requiredSections.every((section) => 
      analysis.containsKey(section) && 
      analysis[section]?.trim().isNotEmpty == true
    );

    if (!isValid) {
      debugPrint('❌ Missing sections: ${_getMissingSections(analysis)}');
    }

    return isValid;
  }
}