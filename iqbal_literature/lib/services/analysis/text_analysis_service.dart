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
      return cachedResult;
    }

    try {
      debugPrint('📝 Attempting word analysis with Gemini...');
      final analysis = await _tryGeminiWordAnalysis(word);
      await _cacheService.cacheWordAnalysis(word, analysis);
      await _cacheService.incrementRequestCount();
      return analysis;
    } catch (e) {
      debugPrint('⚠️ Gemini API failed: $e');

      try {
        return await _fallbackToDeepSeek(word);
      } catch (deepSeekError) {
        debugPrint('❌ DeepSeek API also failed: $deepSeekError');
        // Return default response when both APIs fail
        return _getDefaultWordAnalysis(word);
      }
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

      // Return string format for backward compatibility
      final Map<String, dynamic> analysis =
          await _getAnalysisMap(poemId, contentToAnalyze);
      return _formatPoemAnalysis(analysis);
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
      return cachedResult;
    }

    try {
      debugPrint('📝 Attempting Gemini analysis for poem #$poemId...');
      final analysis = await GeminiAPI.analyzePoemContent(text);

      // Cache the analysis
      await _cacheService.cachePoemAnalysis(poemId, analysis);
      await _cacheService.incrementRequestCount();
      return analysis;
    } catch (e) {
      debugPrint('❌ Analysis failed: $e');
      throw Exception('Failed to analyze poem');
    }
  }

  String _formatPoemAnalysis(Map<String, dynamic> analysis) {
    return '''
Summary
${analysis['summary'] ?? 'Not available'}

Themes
${analysis['themes'] ?? 'Not available'}

Historical & Cultural Context
${analysis['context'] ?? 'Not available'}

Literary Analysis
${analysis['analysis'] ?? 'Not available'}''';
  }

  Future<List<Map<String, dynamic>>> getTimelineEvents(
      int bookId, String bookTitle) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached');
    }

    // Try to get from cache first
    final cachedResult = await _cacheService.getTimelineEvents(bookId);
    if (cachedResult != null) {
      return cachedResult;
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

  Future<String?> _tryGeminiAnalysis(String text) async {
    final prompt = _getAnalysisPrompt(text);
    final response = await GeminiAPI.generateContent(
      prompt: prompt,
      temperature: 0.7,
      maxTokens: 2000,
    );
    return response;
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

  Future<String> _tryDeepSeekAnalysis(String text) async {
    // Changed parameter name from 'prompt' to 'text'
    final prompt = '''
    As an expert in Urdu and Persian poetry analysis, provide a detailed and comprehensive analysis of this poem. Use rich, academic language and specific examples from the text:

    $text

    Structure your analysis as follows:

    1. SUMMARY (6-8 sentences)
    - Core meaning and central message
    - Poetic techniques and devices employed
    - Emotional resonance and impact
    - Connection to broader themes in Iqbal's work
    - Cultural and historical context
    - Literary significance

    2. THEMES (6-8 major themes)
    • [Theme 1] - Detailed explanation with textual evidence
    • [Theme 2] - Analysis of symbolic representation
    • [Theme 3] - Connection to Iqbal's philosophy
    • [Additional themes with specific verse references]

    3. HISTORICAL & CULTURAL CONTEXT (8-10 sentences)
    - Time period and historical backdrop
    - Cultural influences and references
    - Religious and philosophical underpinnings
    - Political and social climate
- Contemporary relevance and modern interpretation

    4. LITERARY DEVICES & TECHNIQUE (Comprehensive analysis)
    • Imagery: Detailed analysis of visual elements
    • Metaphors: Extended explanation of figurative language
    • Symbolism: Deep dive into symbolic meanings
    • Form: Technical analysis of poetic structure
    • Rhyme & Meter: Details of prosodic elements
    • Language: Study of word choice and diction

    5. VERSE-BY-VERSE ANALYSIS
    [Include specific analysis of key verses with:
    - Word choice significance
    - Hidden meanings
    - Technical elements
    - Thematic connections]

    6. PHILOSOPHICAL DIMENSIONS
    - Connection to Islamic thought
    - Relationship to Persian poetic tradition
    - Universal philosophical themes
    - Modern relevance and interpretation

    7. IMPACT & SIGNIFICANCE
    - Literary importance
    - Cultural influence
    - Contemporary relevance
    - Legacy in Urdu/Persian poetry

    Provide extensive textual evidence and specific examples throughout the analysis.
    ''';

    final response = await _apiClient.analyze(
      prompt: prompt,
      maxTokens: 2000, // Increased token limit
      temperature: 0.7,
    );

    return response['choices'][0]['message']['content'];
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
      throw e;
    }
  }

  Map<String, dynamic> _getDefaultWordAnalysis(String word) {
    return {
      "meaning": {
        "english": "Unable to analyze at this time",
        "urdu": "اس وقت تجزیہ کرنے کے قابل نہیں"
      },
      "pronunciation": "Not available",
      "partOfSpeech": "Unknown",
      "examples": ["Example not available"]
    };
  }
}
