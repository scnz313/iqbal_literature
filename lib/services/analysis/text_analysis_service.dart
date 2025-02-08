import '../api/deepseek_api_client.dart';
import '../api/openrouter_service.dart';

import '../cache/analysis_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class TextAnalysisService {
  final DeepSeekApiClient _apiClient;
  final AnalysisCacheService _cacheService;

  TextAnalysisService(this._apiClient, this._cacheService);

  Future<Map<String, dynamic>> analyzeWord(String word) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached (100 requests)');
    }

    final cacheKey = 'word_$word';
    final cachedResult = await _cacheService.getCachedAnalysis(cacheKey);
    if (cachedResult != null) {
      return jsonDecode(cachedResult);
    }

    try {
      debugPrint('Attempting word analysis with DeepSeek API...');
      final analysis = await _tryDeepSeekWordAnalysis(word);
      await _cacheAnalysis(cacheKey, jsonEncode(analysis));
      return analysis;
    } catch (e) {
      debugPrint('DeepSeek API failed: $e');
      debugPrint('Falling back to OpenRouter API...');
      
      try {
        return await OpenRouterService.analyzeWord(word);
      } catch (e) {
        debugPrint('OpenRouter API also failed: $e');
        throw Exception('All analysis services failed');
      }
    }
  }

  Future<String> analyzePoem(String text) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached (100 requests)');
    }

    final cacheKey = 'poem_${text.hashCode}';
    final cachedResult = await _cacheService.getCachedAnalysis(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }

    String? analysis;
    List<String> errors = [];

    // Try DeepSeek first
    try {
      debugPrint('Attempting analysis with DeepSeek API...');
      analysis = await _tryDeepSeekAnalysis(text);
    } catch (e) {
      debugPrint('DeepSeek API failed: $e');
      errors.add('DeepSeek: ${e.toString()}');
    }

    

    // Try OpenRouter last
    if (analysis == null) {
      try {
        debugPrint('Falling back to OpenRouter API...');
        final response = await OpenRouterService.analyzePoem(text);
        analysis = response['content'];
      } catch (e) {
        debugPrint('OpenRouter API failed: $e');
        errors.add('OpenRouter: ${e.toString()}');
        throw Exception('All analysis services failed:\n${errors.join('\n')}');
      }
    }

    if (analysis != null) {
      await _cacheAnalysis(cacheKey, analysis);
      return analysis;
    }

    throw Exception('Unable to analyze poem. Services failed:\n${errors.join('\n')}');
  }

  Future<String> _tryDeepSeekAnalysis(String text) async { // Changed parameter name from 'prompt' to 'text'
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

  Future<void> _cacheAnalysis(String key, String analysis) async {
    await _cacheService.cacheAnalysis(key, analysis);
    await _cacheService.incrementRequestCount();
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
}
