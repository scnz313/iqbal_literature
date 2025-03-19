import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service class for interacting with Google's Gemini API
class GeminiAPI {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static String? _apiKey;

  /// Configure the API key for Gemini
  static void configure(String apiKey) {
    _apiKey = apiKey;
    debugPrint(
        '🔑 Gemini API configured with key: ${apiKey.substring(0, 5)}...');
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
            'topP': 1,
            'topK': 40,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (data['candidates'] == null ||
            data['candidates'].isEmpty ||
            data['candidates'][0]['content'] == null ||
            data['candidates'][0]['content']['parts'] == null ||
            data['candidates'][0]['content']['parts'].isEmpty ||
            data['candidates'][0]['content']['parts'][0]['text'] == null) {
          debugPrint('⚠️ Invalid response format from Gemini API');
          debugPrint('📄 Raw response: ${response.body}');
          throw Exception('Invalid response format from Gemini API');
        }

        final content = data['candidates'][0]['content']['parts'][0]['text'];
        return content.toString().trim();
      }

      debugPrint(
          '❌ Gemini API Error: [${response.statusCode}] ${response.body}');
      throw Exception(
          'Gemini API Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('❌ Gemini API Error: $e');
      rethrow;
    }
  }

  static String _sanitizeText(String text) {
    return text
        .replaceAll(RegExp(r'[^\x20-\x7E\s.,!?()-]'), '') // Keep only ASCII
        .replaceAll('"', "'")
        .replaceAll('"', "'")
        .replaceAll('"', "'")
        .replaceAll(''', "'")
        .replaceAll(''', "'").trim();
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
      final cleanedResponse =
          response.replaceAll('**', '').replaceAll('*', '').trim();

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
        if (entry.value.isNotEmpty) {
          debugPrint(
              '${entry.key}: ${entry.value.substring(0, min(50, entry.value.length))}...');
        }
      }

      if (!_isValidAnalysis(result)) {
        debugPrint('⚠️ Invalid analysis format - missing sections');
        throw Exception('Invalid response format - missing sections');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Gemini analysis error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTimelineEvents(String bookName,
      [String? timePeriod]) async {
    if (!isConfigured) {
      throw Exception('Gemini API not configured');
    }

    try {
      debugPrint('📝 Requesting timeline from Gemini...');
      final response = await generateContent(
        prompt: _getTimelinePrompt(bookName, timePeriod),
        temperature: 0.3,
        maxTokens: 2000,
      );

      // Clean and parse JSON
      final cleanedJson = _safelyCleanJson(response);
      if (cleanedJson == null) {
        debugPrint('⚠️ Using default timeline due to cleaning failure');
        return _getDefaultTimelineEvents(bookName);
      }

      try {
        final List<dynamic> parsedEvents = jsonDecode(cleanedJson);
        return parsedEvents.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('❌ JSON parsing error: $e');
        return _getDefaultTimelineEvents(bookName);
      }
    } catch (e) {
      debugPrint('❌ Timeline generation error: $e');
      return _getDefaultTimelineEvents(bookName);
    }
  }

  static String? _safelyCleanJson(String response) {
    try {
      // Extract JSON array
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart < 0 || jsonEnd <= jsonStart) {
        return null;
      }

      var extracted = response.substring(jsonStart, jsonEnd);

      // Basic cleanup
      extracted = extracted
          .replaceAll(
              RegExp(r'[\u2018\u2019\u201C\u201D]'), '"') // Smart quotes
          .replaceAll('"', '"')
          .replaceAll('"', '"')
          .replaceAll(''', "'")
          .replaceAll(''', "'")
          .replaceAll('–', '-')
          .replaceAll('…', '...');

      // Remove any remaining problematic characters
      extracted = extracted.replaceAll(RegExp(r'[^\x20-\x7E\s]'), '');

      // Validate JSON
      jsonDecode(extracted); // Test parse
      return extracted;
    } catch (e) {
      debugPrint('❌ JSON cleaning error: $e');
      return null;
    }
  }

  // Validate that the analysis contains all required sections
  static bool _isValidAnalysis(Map<String, String> analysis) {
    final requiredSections = ['summary', 'themes', 'context', 'analysis'];

    // Check if all required sections are present and not empty
    for (final section in requiredSections) {
      if (!analysis.containsKey(section) || analysis[section]!.isEmpty) {
        debugPrint('⚠️ Missing required section: $section');
        return false;
      }
    }

    return true;
  }

  static String _getTimelinePrompt(String bookName, [String? timePeriod]) {
    return '''Create a timeline of key historical events related to Allama Iqbal's "${bookName}" ${timePeriod != null ? 'during the $timePeriod period' : ''}.

Return ONLY a JSON array in this exact format, with no additional text or explanation:
[
  {
    "year": "YYYY", // Example: "1930" (or a range like "1930-1932")
    "title": "Short event title",
    "description": "Detailed description of the event (2-3 sentences)",
    "significance": "Why this event matters in context of the book (1-2 sentences)"
  },
  // Include 8-12 events in chronological order
]

INCLUDE ONLY the JSON array with no other text. Ensure the JSON is properly formatted with double quotes for all keys and string values.''';
  }

  static List<Map<String, dynamic>> _getDefaultTimelineEvents(String bookName) {
    return [
      {
        "year": "1905",
        "title": "Publication of Asrar-e-Khudi",
        "description":
            "Iqbal published his seminal work focusing on the concept of selfhood and self-realization. This Persian poem introduced his philosophical vision.",
        "significance":
            "Marked Iqbal's emergence as a major philosophical poet and established his core themes."
      },
      {
        "year": "1908",
        "title": "Iqbal's Return to India",
        "description":
            "After completing his education in Europe, Iqbal returned to India with new philosophical perspectives. His European experience deeply influenced his worldview.",
        "significance":
            "Began synthesis of Eastern and Western thought that would characterize his literary output."
      },
      {
        "year": "1915",
        "title": "Publication of Asrar-o-Rumuz",
        "description":
            "Released collection of Persian poetry exploring deeper mystical and philosophical concepts. This work expanded on ideas introduced in earlier writings.",
        "significance":
            "Solidified Iqbal's reputation as the philosophical poet of Islamic revival."
      },
      {
        "year": "1923",
        "title": "Political Awakening Period",
        "description":
            "Iqbal became more actively involved in politics and the Muslim cause in India. His poetry began reflecting greater political consciousness.",
        "significance":
            "Poetry from this period shows growing concern with the practical implications of his philosophy."
      },
      {
        "year": "1930",
        "title": "Allahabad Address",
        "description":
            "Delivered famous speech proposing the idea of a separate Muslim state in Northwest India. This address is considered a foundational document for Pakistan.",
        "significance":
            "Demonstrated how Iqbal's philosophical ideas translated into political vision."
      },
      {
        "year": "1938",
        "title": "Iqbal's Death",
        "description":
            "Allama Muhammad Iqbal passed away in Lahore on April 21, 1938. His literary legacy included poetry in Persian and Urdu that transformed Muslim intellectual thought.",
        "significance":
            "His works continued to inspire the Pakistan movement and Islamic revival worldwide."
      }
    ];
  }

  // Historical context analysis
  static Future<Map<String, dynamic>> getHistoricalContext(
      String title, String poemText) async {
    try {
      final prompt = '''
Analyze this poem by Allama Iqbal comprehensively:
TITLE: $title

TEXT:
$poemText

Provide a JSON response with EXACTLY these fields:
{
  "year": "When this poem was likely written (best estimate if exact date unknown)",
  "historicalContext": "Detailed historical background (3-4 sentences)",
  "significance": "Cultural and literary significance (3-4 sentences)",
  "culturalImportance": "How it relates to Muslim/South Asian culture (2-3 sentences)",
  "religiousThemes": "Religious aspects and Islamic philosophy references (2-3 sentences)",
  "politicalMessages": "Political themes or messages (2-3 sentences)",
  "factualInformation": "Any specific factual or historical references in the poem (2-3 sentences)",
  "imagery": "Key imagery used and its significance (2-3 examples)",
  "metaphor": "Major metaphors and their meaning (2-3 examples)",
  "symbolism": "Important symbols and their interpretations (2-3 examples)",
  "theme": "The overarching theme and message (2-3 sentences)"
}

Return ONLY the JSON with no other explanation.''';

      final response = await generateContent(
        prompt: prompt,
        temperature: 0.3,
        maxTokens: 2000,
      );

      try {
        // Try to extract JSON from the response
        String jsonStr = response.trim();

        // If response contains text before/after JSON
        int startPos = jsonStr.indexOf('{');
        int endPos = jsonStr.lastIndexOf('}') + 1;

        if (startPos >= 0 && endPos > startPos) {
          jsonStr = jsonStr.substring(startPos, endPos);
        }

        final data = jsonDecode(jsonStr);
        return data;
      } catch (e) {
        debugPrint('❌ Failed to parse historical context JSON: $e');
        debugPrint('Raw response: $response');

        // Return a structured fallback
        return {
          "year": "Unknown",
          "historicalContext":
              "Historical context could not be determined with confidence.",
          "significance":
              "This poem is part of Iqbal's body of work exploring themes of self-realization and Islamic revival.",
          "culturalImportance":
              "Iqbal's poetry is central to South Asian literary tradition and Islamic philosophical thought.",
          "religiousThemes":
              "Likely contains Iqbal's typical references to Islamic spirituality and philosophy.",
          "politicalMessages":
              "May reflect Iqbal's vision for Muslim revival and self-determination.",
          "factualInformation":
              "Analysis unavailable due to technical limitations.",
          "imagery": "Analysis unavailable.",
          "metaphor": "Analysis unavailable.",
          "symbolism": "Analysis unavailable.",
          "theme":
              "Likely explores one of Iqbal's central themes of selfhood, spiritual awakening, or Muslim identity."
        };
      }
    } catch (e) {
      debugPrint('❌ Historical context generation error: $e');
      return {
        "year": "Unavailable",
        "historicalContext": "Analysis unavailable due to technical error.",
        "significance": "Please try again later.",
        "culturalImportance": "",
        "religiousThemes": "",
        "politicalMessages": "",
        "factualInformation": "",
        "imagery": "",
        "metaphor": "",
        "symbolism": "",
        "theme": ""
      };
    }
  }
}
