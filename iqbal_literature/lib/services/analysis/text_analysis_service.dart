import '../api/deepseek_api_client.dart';
import '../api/gemini_api.dart';
import '../cache/analysis_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class TextAnalysisService {
  final DeepSeekApiClient _apiClient;
  final AnalysisCacheService _cacheService;

  TextAnalysisService(this._apiClient, this._cacheService);

  Future<Map<String, dynamic>> analyzeWord(String word) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached');
    }

    // Try to get from cache first
    final cachedResult = await _cacheService.getWordAnalysis(word);
    if (cachedResult != null) {
      try {
        // Create a fresh Map<String, dynamic> with explicit types
        final Map<String, dynamic> analysis = <String, dynamic>{};

        // Handle the meaning map specifically
        if (cachedResult['meaning'] is Map) {
          final meaningMap = <String, String>{};
          final rawMeaning = cachedResult['meaning'] as Map;
          meaningMap['english'] =
              rawMeaning['english']?.toString() ?? 'Not available';
          meaningMap['urdu'] =
              rawMeaning['urdu']?.toString() ?? 'Not available';
          analysis['meaning'] = meaningMap;
        } else {
          analysis['meaning'] = {
            'english': 'Not available',
            'urdu': 'Not available'
          };
        }

        // Add other properties with safe conversions
        analysis['pronunciation'] =
            cachedResult['pronunciation']?.toString() ?? 'Not available';
        analysis['partOfSpeech'] =
            cachedResult['partOfSpeech']?.toString() ?? 'Unknown';

        // Handle examples safely
        if (cachedResult['examples'] is List) {
          analysis['examples'] = (cachedResult['examples'] as List)
              .map((e) => e.toString())
              .toList();
        } else {
          analysis['examples'] = ['Example not available'];
        }

        return analysis;
      } catch (e) {
        debugPrint('❌ Word analysis error: $e');
        // If there was an error, proceed to get a fresh analysis
      }
    }

    try {
      debugPrint('📝 Attempting word analysis with Gemini...');
      // We need to be extra careful with the API response
      Map<String, dynamic> rawAnalysis;

      try {
        rawAnalysis = await _tryGeminiWordAnalysis(word);
      } catch (geminiError) {
        debugPrint('⚠️ Gemini API failed: $geminiError');
        // Try DeepSeek as fallback
        try {
          rawAnalysis = await _tryDeepSeekWordAnalysis(word);
        } catch (deepSeekError) {
          debugPrint('❌ DeepSeek API also failed: $deepSeekError');
          // If both APIs fail, return a default response
          return _getDefaultWordAnalysis(word);
        }
      }

      // Convert the result to a properly typed Map<String, dynamic>
      final Map<String, dynamic> analysis = <String, dynamic>{};

      // Handle the meaning map
      final Map<String, String> meaning = <String, String>{};
      if (rawAnalysis['meaning'] is Map) {
        final rawMeaning = rawAnalysis['meaning'] as Map;
        meaning['english'] =
            rawMeaning['english']?.toString() ?? 'Not available';
        meaning['urdu'] = rawMeaning['urdu']?.toString() ?? 'Not available';
      } else {
        meaning['english'] = 'Not available';
        meaning['urdu'] = 'Not available';
      }
      analysis['meaning'] = meaning;

      // Handle other fields with proper conversions
      analysis['pronunciation'] =
          rawAnalysis['pronunciation']?.toString() ?? 'Not available';
      analysis['partOfSpeech'] =
          rawAnalysis['partOfSpeech']?.toString() ?? 'Unknown';

      // Handle examples array
      if (rawAnalysis['examples'] is List) {
        analysis['examples'] =
            (rawAnalysis['examples'] as List).map((e) => e.toString()).toList();
      } else {
        analysis['examples'] = ['Example not available'];
      }

      // Cache the properly typed result
      await _cacheService.cacheWordAnalysis(word, analysis);
      await _cacheService.incrementRequestCount();
      return analysis;
    } catch (e) {
      debugPrint('❌ Word analysis completely failed: $e');
      return _getDefaultWordAnalysis(word);
    }
  }

  Future<Map<String, dynamic>> _fallbackToDeepSeek(String word) async {
    try {
      debugPrint('📝 Falling back to DeepSeek API...');
      final analysis = await _tryDeepSeekWordAnalysis(word);
      await _cacheService.cacheWordAnalysis(word, analysis);
      await _cacheService.incrementRequestCount();
      return analysis;
    } catch (e) {
      debugPrint('❌ DeepSeek API also failed: $e');
      return _getDefaultWordAnalysis(word);
    }
  }

  Future<dynamic> analyzePoem(dynamic poemIdOrText, [String? text]) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached');
    }

    // Handle both calling conventions:
    // Old: analyzePoem(String text)
    // New: analyzePoem(int poemId, String text)
    final String contentToAnalyze;
    final int poemId;

    if (text == null) {
      // Old calling convention - single text parameter
      contentToAnalyze = poemIdOrText as String;
      poemId = contentToAnalyze.hashCode;

      // We want to return either the formatted string OR the original map data to be flexible
      try {
        final Map<String, dynamic> analysis =
            await _getAnalysisMap(poemId, contentToAnalyze);
        // Try to format it as a string
        final String formatted = _formatPoemAnalysis(analysis);

        debugPrint('📝 Successfully formatted poem analysis to string');
        return formatted;
      } catch (formattingError) {
        debugPrint('⚠️ Error formatting analysis: $formattingError');
        // If formatting fails, return the raw map which might be more usable
        final Map<String, dynamic> rawAnalysis =
            await _getAnalysisMap(poemId, contentToAnalyze);
        debugPrint('📝 Returning raw analysis map instead');
        return rawAnalysis;
      }
    } else {
      // New calling convention with poemId and text
      poemId = poemIdOrText as int;
      contentToAnalyze = text;

      // Return the map directly for new code
      return await _getAnalysisMap(poemId, contentToAnalyze);
    }
  }

  Future<Map<String, dynamic>> _getAnalysisMap(int poemId, String text) async {
    // Try to get from cache first
    final cachedResult = await _cacheService.getPoemAnalysis(poemId);
    if (cachedResult != null) {
      try {
        // Create a fresh Map<String, dynamic> with explicit typing to avoid any casting issues
        final Map<String, dynamic> analysis = <String, dynamic>{};

        // Extract each field with proper string conversion
        analysis['summary'] =
            cachedResult['summary']?.toString() ?? 'Not available';
        analysis['themes'] =
            cachedResult['themes']?.toString() ?? 'Not available';
        analysis['context'] =
            cachedResult['context']?.toString() ?? 'Not available';
        analysis['analysis'] =
            cachedResult['analysis']?.toString() ?? 'Not available';

        return analysis;
      } catch (e) {
        debugPrint('❌ Analysis cache error: $e');
        // If there was an error with the cache, proceed to get a fresh analysis
      }
    }

    try {
      debugPrint('📝 Attempting Gemini analysis for poem #$poemId...');

      try {
        // GeminiAPI returns Map<String, dynamic>
        final response = await GeminiAPI.analyzePoemContent(text);

        // Explicitly convert to Map<String, dynamic> to ensure correct typing
        final Map<String, dynamic> analysis = <String, dynamic>{};

        // Process each key-value pair individually to ensure proper typing
        analysis['summary'] =
            response['summary']?.toString() ?? 'Analysis not available';
        analysis['themes'] =
            response['themes']?.toString() ?? 'Themes not available';
        analysis['context'] =
            response['context']?.toString() ?? 'Context not available';
        analysis['analysis'] = response['analysis']?.toString() ??
            'Literary analysis not available';

        // Cache the properly typed analysis
        await _cacheService.cachePoemAnalysis(poemId, analysis);
        await _cacheService.incrementRequestCount();
        return analysis;
      } catch (apiError) {
        debugPrint('❌ Gemini API error: $apiError');

        // Return a properly formatted default response
        return <String, dynamic>{
          'summary':
              'API service unavailable. Please check your internet connection.',
          'themes': 'Analysis service is currently unavailable.',
          'context': 'Please try again later.',
          'analysis':
              'We apologize for the inconvenience. Error details: $apiError'
        };
      }
    } catch (e) {
      debugPrint('❌ Analysis completely failed: $e');

      // Return default values for all analysis sections
      return <String, dynamic>{
        'summary': 'Unable to analyze poem at this time.',
        'themes': 'Analysis service is currently unavailable.',
        'context': 'Please check your internet connection and try again later.',
        'analysis': 'We apologize for the inconvenience.'
      };
    }
  }

  String _formatPoemAnalysis(Map<String, dynamic> analysisData) {
    try {
      // Get each section, providing default values if sections are missing
      final summary = analysisData['summary'] ?? 'Summary not available';
      final themes = analysisData['themes'] ?? 'Themes not available';
      final context =
          analysisData['context'] ?? 'Historical context not available';
      final analysis =
          analysisData['analysis'] ?? 'Literary analysis not available';

      // Format themes section - if it's not a bulleted list already, keep as is
      String formattedThemes = themes;
      if (!themes.contains('•') && !themes.contains('-')) {
        // First try to extract themes separated by commas or semicolons
        if (themes.contains(',') || themes.contains(';')) {
          final themeItems = themes
              .split(RegExp(r'[,;]'))
              .where((item) => item.trim().isNotEmpty)
              .toList();

          if (themeItems.length > 1) {
            formattedThemes =
                themeItems.map((theme) => '• ${theme.trim()}').join('\n');
          }
        }
        // Then try to extract themes from lines if comma separation didn't work
        else if (themes.contains('\n')) {
          final themeLines = themes
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();

          if (themeLines.length > 1) {
            formattedThemes =
                themeLines.map((theme) => '• ${theme.trim()}').join('\n');
          }
        }
        // If nothing worked, wrap the whole text as a single theme
        else if (!formattedThemes.startsWith('•') &&
            !formattedThemes.startsWith('-')) {
          formattedThemes = '• $themes';
        }
      }

      // Format each section with appropriate headers and spacing
      return '''
Summary:
$summary

Themes:
$formattedThemes

Historical & Cultural Context:
$context

Literary Analysis:
$analysis
''';
    } catch (e) {
      debugPrint('❌ Error formatting poem analysis: $e');
      // Fallback - try to use string values directly if they exist
      try {
        final sections = <String>[];

        if (analysisData.containsKey('summary')) {
          sections.add('Summary:\n${analysisData['summary']}');
        }

        if (analysisData.containsKey('themes')) {
          sections.add('Themes:\n${analysisData['themes']}');
        }

        if (analysisData.containsKey('context')) {
          sections.add(
              'Historical & Cultural Context:\n${analysisData['context']}');
        }

        if (analysisData.containsKey('analysis')) {
          sections.add('Literary Analysis:\n${analysisData['analysis']}');
        }

        // If we have any sections, return them; otherwise, use a generic message
        if (sections.isNotEmpty) {
          return sections.join('\n\n');
        }
      } catch (_) {
        // Last resort fallback
      }

      return 'Analysis could not be formatted properly. Please try again later.';
    }
  }

  Future<List<Map<String, dynamic>>> getTimelineEvents(
      int bookId, String bookTitle) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached');
    }

    // Try to get from cache first
    final cachedResult = await _cacheService.getTimelineEvents(bookId);
    if (cachedResult != null) {
      try {
        // Properly cast the list of maps
        return cachedResult
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (e) {
        debugPrint('❌ Timeline retrieval error: $e');
        // If there was an error, proceed to get fresh timeline
      }
    }

    try {
      debugPrint('📝 Generating timeline for book #$bookId...');
      final events = await GeminiAPI.getTimelineEvents(bookTitle);

      // Cache the timeline
      await _cacheService.cacheTimelineEvents(bookId, events);
      await _cacheService.incrementRequestCount();
      return events;
    } catch (e) {
      debugPrint('❌ Timeline generation failed: $e');
      throw Exception('Failed to generate timeline');
    }
  }

  String _getAnalysisPrompt(String text) {
    return '''Analyze this poem and provide detailed analysis:
    
$text

Structure your analysis as follows:

1. SUMMARY (6-8 sentences)
2. THEMES (6-8 major themes)
3. HISTORICAL & CULTURAL CONTEXT
4. LITERARY DEVICES & TECHNIQUE
5. VERSE-BY-VERSE ANALYSIS
6. PHILOSOPHICAL DIMENSIONS
7. IMPACT & SIGNIFICANCE

Provide extensive evidence and specific examples.''';
  }

  Future<Map<String, dynamic>> _tryDeepSeekWordAnalysis(String word) async {
    final prompt = '''
    Analyze this word: $word
    Return in this exact JSON format:
    {
      "meaning": {
        "english": "English meaning",
        "urdu": "Urdu meaning"
      },
      "pronunciation": "phonetic guide",
      "partOfSpeech": "grammar category",
      "examples": ["example 1", "example 2"]
    }
    ''';

    final response = await _apiClient.analyze(prompt: prompt);
    final content = response['choices'][0]['message']['content'];
    return jsonDecode(content);
  }

  Future<Map<String, dynamic>> _tryGeminiWordAnalysis(String word) async {
    final prompt = '''Analyze this Urdu/Persian word: "$word"

You MUST respond with ONLY a valid JSON object in this exact format, with no additional text:
{
  "meaning": {
    "english": "English meaning",
    "urdu": "Urdu meaning in English transliteration"
  },
  "pronunciation": "phonetic guide",
  "partOfSpeech": "grammar category",
  "examples": ["example 1", "example 2"]
}

Important: Return ONLY the JSON object, nothing else.''';

    try {
      final response = await GeminiAPI.generateContent(
        prompt: prompt,
        temperature:
            0.1, // Very low temperature for deterministic, structured responses
      );

      debugPrint('📝 Gemini Word Analysis Raw Response: $response');

      // Check if response is completely empty
      if (response.isEmpty) {
        debugPrint('⚠️ Empty response from Gemini API');
        throw Exception('Empty response from Gemini API');
      }

      // Try to parse the response as JSON
      try {
        // First check if response contains markdown code blocks (common with Gemini)
        if (response.contains('```json') || response.contains('```')) {
          debugPrint('📝 Detected markdown code block, extracting JSON...');

          // Extract JSON from markdown code block
          final startMarker = response.contains('```json') ? '```json' : '```';
          final endMarker = '```';

          final jsonStart = response.indexOf(startMarker) + startMarker.length;
          final jsonEnd = response.lastIndexOf(endMarker);

          if (jsonStart > 0 && jsonEnd > jsonStart) {
            final jsonStr = response.substring(jsonStart, jsonEnd).trim();
            debugPrint('📝 Extracted JSON from markdown: $jsonStr');
            try {
              return jsonDecode(jsonStr);
            } catch (e) {
              debugPrint('⚠️ Failed to parse extracted JSON: $e');
              // Continue to try other methods
            }
          }
        }

        // Try parsing the entire response as JSON
        try {
          return jsonDecode(response);
        } catch (e) {
          debugPrint('⚠️ Full JSON parsing failed: $e');
        }

        // Try to extract JSON by finding opening/closing braces
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = response
              .substring(jsonStart, jsonEnd)
              .replaceAll(RegExp(r'[""""]'), '"') // Replace all quote variants
              .replaceAll(
                  RegExp(r"['']"), "'"); // Replace all apostrophe variants

          try {
            return jsonDecode(jsonStr);
          } catch (e) {
            debugPrint('⚠️ JSON extraction failed: $e');
          }
        }

        throw Exception('No valid JSON found in Gemini response');
      } catch (e) {
        debugPrint('❌ Gemini API error: $e');
        throw Exception('Gemini API failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Error in Gemini word analysis: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _getDefaultWordAnalysis(String word) {
    // Provide a more helpful fallback with common Urdu/Persian words
    final Map<String, dynamic> commonWords = {
      "ایک": {
        "meaning": {"english": "One", "urdu": "ایک"},
        "pronunciation": "aik/ek",
        "partOfSpeech": "Numeral",
        "examples": [
          "ایک کتاب (ek kitaab) - one book",
          "ایک دن (ek din) - one day"
        ]
      },
      "محبت": {
        "meaning": {"english": "Love", "urdu": "محبت"},
        "pronunciation": "muhabbat",
        "partOfSpeech": "Noun",
        "examples": [
          "محبت سے (muhabbat se) - with love",
          "محبت کرنا (muhabbat karna) - to love"
        ]
      },
      "خدا": {
        "meaning": {"english": "God", "urdu": "خدا"},
        "pronunciation": "khuda",
        "partOfSpeech": "Noun",
        "examples": [
          "خدا کا شکر (khuda ka shukar) - thanks to God",
          "خدا حافظ (khuda hafiz) - goodbye"
        ]
      },
      "زندگی": {
        "meaning": {"english": "Life", "urdu": "زندگی"},
        "pronunciation": "zindagi",
        "partOfSpeech": "Noun",
        "examples": [
          "میری زندگی (meri zindagi) - my life",
          "زندگی کا سفر (zindagi ka safar) - journey of life"
        ]
      }
    };

    // Check if the word is in our common words dictionary
    final String normalizedWord = word.trim().toLowerCase();
    for (final entry in commonWords.entries) {
      if (normalizedWord == entry.key.toLowerCase() ||
          normalizedWord.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(normalizedWord)) {
        debugPrint('📝 Using local dictionary entry for word: $word');
        return Map<String, dynamic>.from(entry.value);
      }
    }

    // If no match found, return standard default response
    return {
      "meaning": {
        "english": "Local analysis for '$word'",
        "urdu": "بغیر انٹرنیٹ تجزیہ"
      },
      "pronunciation": "Not available offline",
      "partOfSpeech": "Unknown",
      "examples": ["Internet connection required for detailed analysis"]
    };
  }
}
