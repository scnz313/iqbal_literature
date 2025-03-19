import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/cache_service.dart';
import '../../services/api/gemini_api.dart';

class OpenRouterService {
  // API Keys and service flags
  static const String? _geminiApiKey =
      'AIzaSyC8sY9B8jI7cpdv8DFbMSmSVqjkwfH_ARQ';
  static const String? _openrouterKey =
      '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';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Updated working models only - removed OpenAI models
  static const Map<String, Map<String, dynamic>> _modelConfigs = {
    'primary': {
      'url': 'https://openrouter.ai/api/v1/chat/completions',
      'models': [
        'deepseek-ai/deepseek-chat-33b', // Primary model
        'meta/llama-2-70b-chat', // First fallback
        'nousresearch/nous-hermes-2-mixtral-8x7b-dpo', // Second fallback
      ],
    },
  };

  // Service status tracking
  static bool _isGeminiAvailable = true;
  static bool _isOpenRouterAvailable = true;
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Cache keys
  static const String _poemAnalysisCache = 'poem_analysis_cache_';
  static const String _timelineCache = 'timeline_cache_';
  static late SharedPreferences _prefs;

  // Initialize cache
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Poem analysis function using Google Cloud Natural Language API
  static Future<Map<String, String>> analyzePoem(String text) async {
    try {
      final cacheKey = text.hashCode.toString();
      final cached = await CacheService.getAnalysis(cacheKey);
      if (cached != null) {
        debugPrint('📝 Using cached analysis');
        return cached;
      }

      // Try Gemini first
      if (GeminiAPI.isConfigured) {
        try {
          debugPrint('📝 Attempting Gemini analysis...');
          final analysis = await GeminiAPI.analyzePoemContent(text);

          // Cache and return successful analysis
          await CacheService.cacheAnalysis(cacheKey, analysis);
          return analysis;
        } catch (e) {
          debugPrint('⚠️ Gemini analysis failed: $e');
        }
      }

      // Rest of the fallback logic...
      // ... existing code ...
    } catch (e) {
      debugPrint('❌ Critical error: $e');
      return _getOfflineAnalysis(text);
    }
    // Add default return in case all attempts fail
    return _getOfflineAnalysis(text);
  }

  static Future<Map<String, String>> _analyzeWithGemini(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      '''Analyze this poem and provide the following sections:
$text

Respond in exactly this format:
SUMMARY:
[2-3 sentences summarizing the poem]

THEMES:
• [Main theme 1]
• [Main theme 2]
• [Main theme 3]

HISTORICAL CONTEXT:
[Brief historical background, 2-3 sentences]

ANALYSIS:
[Literary analysis, 2-3 sentences]'''
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 1000,
            "topP": 1,
            "topK": 40
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Successful Gemini response received');

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

        if (content == null || content.toString().isEmpty) {
          throw Exception('Empty response from Gemini API');
        }

        // Parse and validate content
        final analysis = _parseAnalysisContent(content.toString());
        if (!_isValidAnalysis(analysis)) {
          throw Exception('Invalid analysis format from Gemini');
        }

        return analysis;
      }

      debugPrint(
          '❌ Gemini API error: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Gemini API Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('❌ Gemini API request failed: $e');
      throw Exception('Failed to get response from Gemini: $e');
    }
  }

  static Future<Map<String, String>> _fallbackAnalysis(
      String text, String cacheKey) async {
    // Try OpenRouter models as fallback
    List<Exception> errors = [];
    for (final model in _modelConfigs['primary']!['models']) {
      try {
        debugPrint('📝 Trying $model...');

        final response = await http.post(
          Uri.parse(_modelConfigs['primary']!['url'] as String),
          headers: {
            'Authorization': 'Bearer $_openrouterKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://iqbalbook.app',
            'x-title': 'IqbalBook',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a poetry expert. Analyze the given poem clearly and concisely.'
              },
              {'role': 'user', 'content': text}
            ],
            'temperature': 0.3, // Lower temperature for more focused responses
            'max_tokens': 800, // Reduced for faster responses
          }),
        );

        debugPrint('OpenRouter Response Status: ${response.statusCode}');
        debugPrint('OpenRouter Raw Response: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null && data['choices']?.isNotEmpty == true) {
            final content = data['choices'][0]['message']['content'];
            if (content != null && content.toString().isNotEmpty) {
              final analysis = _parseAnalysisContent(content);
              if (_isValidAnalysis(analysis)) {
                await CacheService.cacheAnalysis(cacheKey, analysis);
                debugPrint('✅ Success with $model');
                return analysis;
              }
            }
          }
        }

        // Handle rate limits by waiting before trying next model
        if (response.statusCode == 429) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        if (response.statusCode == 402 || response.statusCode == 429) {
          debugPrint('⚠️ Model $model quota exceeded, trying next...');
          continue;
        }
      } catch (e) {
        debugPrint('❌ $model failed: $e');
        errors.add(Exception('$model: $e'));
        continue;
      }
    }

    // If all models failed, throw a combined exception
    throw Exception(
        'Unable to analyze poem. Services failed:\n${errors.map((e) => e.toString()).join('\n')}');
  }

  // Add validation for analysis results
  static bool _isValidAnalysis(Map<String, String> analysis) {
    return analysis.containsKey('summary') &&
        analysis.containsKey('themes') &&
        analysis.containsKey('context') &&
        analysis.containsKey('analysis') &&
        analysis.values.every((v) => v.trim().isNotEmpty);
  }

  static Future<Map<String, String>> _analyzeWithModel(
    String text,
    String model, {
    String? prompt,
  }) async {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openrouterKey',
        'HTTP-Referer': 'https://iqbalbook.app',
        'x-title': 'IqbalBook',
      },
      body: jsonEncode({
        "model": model,
        "messages": [
          {
            "role": "system",
            "content":
                "You are a literary expert specializing in poetry analysis."
          },
          {"role": "user", "content": prompt ?? "Analyze this poem:\n\n$text"}
        ],
        "temperature": 0.5,
        "max_tokens": 1000,
      }),
    );

    if (response.statusCode == 200) {
      final content =
          jsonDecode(response.body)['choices'][0]['message']['content'];
      final analysis = _parseAnalysisContent(content);

      if (_isValidAnalysis(analysis)) {
        return analysis;
      }
      throw Exception('Invalid analysis format');
    }

    throw Exception('API Error: ${response.statusCode}');
  }

  static Future<Map<String, String>> _analyzeWithDeepseek(String text) async {
    final response = await http.post(
      Uri.parse(_modelConfigs['fallback']!['url'] as String),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openrouterKey',
      },
      body: jsonEncode({
        "model": "deepseek-chat",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a literary expert analyzing Urdu and Persian poetry."
          },
          {"role": "user", "content": "Analyze this poem in English:\n\n$text"}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final content =
          jsonDecode(response.body)['choices'][0]['message']['content'];
      return _parseAnalysisContent(content);
    }
    throw Exception('DeepSeek API Error: ${response.statusCode}');
  }

  static void _cacheAnalysis(String key, Map<String, String> analysis) {
    try {
      _prefs.setString(key, jsonEncode(analysis));
      debugPrint('📝 Analysis cached successfully');
    } catch (e) {
      debugPrint('❌ Cache error: $e');
    }
  }

  static Map<String, String> _getOfflineAnalysis(String text) {
    return {
      'summary': 'Analysis currently unavailable. Please try again later.',
      'themes':
          '• Theme analysis unavailable\n• Please check your internet connection\n• Try again in a few minutes',
      'context': 'Historical context analysis is temporarily unavailable.',
      'analysis':
          '• Analysis service is currently offline\n• Please try again later\n• If the problem persists, contact support',
    };
  }

  static Map<String, String> _parseAnalysisContent(String content) {
    try {
      final result = <String, String>{};
      final sections = content.split('\n\n');

      for (var section in sections) {
        section = section.replaceAll('**', '').replaceAll('*', '').trim();

        if (section.startsWith('SUMMARY:')) {
          result['summary'] = section.substring('SUMMARY:'.length).trim();
        } else if (section.startsWith('THEMES:')) {
          result['themes'] = section.substring('THEMES:'.length).trim();
        } else if (section.startsWith('HISTORICAL CONTEXT:')) {
          result['context'] =
              section.substring('HISTORICAL CONTEXT:'.length).trim();
        } else if (section.startsWith('ANALYSIS:')) {
          result['analysis'] = section.substring('ANALYSIS:'.length).trim();
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Parse error: $e');
      throw Exception('Failed to parse analysis');
    }
  }

  static Map<String, String> _getDefaultPoemAnalysis() {
    return {
      'summary': 'Analysis unavailable',
      'themes': 'No themes available',
      'context': 'No historical context available',
      'analysis': 'No analysis available',
    };
  }

  static String _cleanAndFormatAnalysis(String content) {
    try {
      // First clean the text
      var cleaned = _cleanTextAdvanced(content);

      // Then format the sections
      cleaned = cleaned
          .replaceAll('â¢', '•')
          .replaceAll('‣', '•')
          .replaceAll('⁃', '•')
          .replaceAll('−', '•')
          .replaceAll('-', '•');

      // Split and format sections
      final sections = cleaned.split('\n\n');
      final formattedSections = sections.map((section) {
        final lines = section.split('\n');
        if (lines.isEmpty) return '';

        return lines.map((line) {
          line = line.trim();
          if (line.startsWith('•')) {
            final text = line.substring(1).trim();
            return '  • $text';
          }
          return line;
        }).join('\n');
      }).join('\n\n');

      return formattedSections;
    } catch (e) {
      debugPrint('Error formatting analysis: $e');
      return content;
    }
  }

  static String _cleanTextAdvanced(String text) {
    try {
      // First decode UTF-8
      var decoded = utf8.decode(utf8.encode(text));

      // Replace common problematic characters
      var cleaned = decoded
          .replaceAll('Ø', '')
          .replaceAll('Ù', '')
          .replaceAll('Ø²', '')
          .replaceAll('Û', '')
          .replaceAll('Ø®', '')
          .replaceAll('Ø¯', '')
          .replaceAll('Ù¨', '')
          .replaceAll('�', '')
          .replaceAll('â', "'")
          .replaceAll('€™', "'")
          .replaceAll('â€œ', '"')
          .replaceAll('â€', '"');

      // Keep only ASCII characters and basic punctuation
      cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E\s.,!?()-]'), '');

      // Fix multiple spaces and lines
      return cleaned
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')
          .trim();
    } catch (e) {
      debugPrint('Error cleaning text: $e');
      return text;
    }
  }

  static Future<Map<String, dynamic>> analyzeWord(String word) async {
    try {
      if (word.trim().isEmpty) {
        return _getDefaultWordAnalysis('No word provided');
      }

      final response = await http.post(
        Uri.parse(_modelConfigs['primary']!['url'] as String),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openrouterKey',
          'HTTP-Referer': 'https://iqbalbook.app',
          'X-Title': 'IqbalBook',
        },
        body: jsonEncode({
          "model": _modelConfigs['primary']!['models'][0], // Use primary model
          "messages": [
            {
              "role": "system",
              "content":
                  "Analyze Urdu/Persian words and return JSON format responses."
            },
            {
              "role": "user",
              "content": """Analyze this word: $word
              Return in this exact JSON format:
              {
                "meaning": {
                  "english": "English meaning",
                  "urdu": "Urdu meaning"
                },
                "pronunciation": "phonetic guide",
                "partOfSpeech": "grammar category",
                "examples": ["example 1", "example 2"]
              }"""
            }
          ],
          "temperature": 0.7,
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return jsonDecode(content);
        }
      }
      return _getDefaultWordAnalysis(word);
    } catch (e) {
      debugPrint('Word Analysis Error: $e');
      return _getDefaultWordAnalysis(word);
    }
  }

  static Map<String, dynamic> _getDefaultWordAnalysis(String word) {
    return {
      'meaning': {'english': 'Analysis unavailable', 'urdu': word},
      'pronunciation': 'Not available',
      'partOfSpeech': 'Not available',
      'examples': ['Not available']
    };
  }

  static Future<String> getCompletion(String prompt) async {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openrouterKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'anthropic/claude-2',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a knowledgeable assistant specializing in Iqbal\'s poetry and Islamic history.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get completion: ${response.statusCode}');
    }
  }

  static Future<Map<String, String>> getHistoricalContext(
      String title, String content) async {
    try {
      debugPrint('📡 Starting historical context analysis for: $title');

      // Clean the title for the API request
      final cleanTitle = _cleanText(title);

      final response = await http.post(
        Uri.parse(_modelConfigs['primary']!['url'] as String),
        headers: {
          'Authorization': 'Bearer $_openrouterKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://iqbalbook.app',
          'X-Title': 'IqbalBook',
          'User-Agent': 'IqbalBook/1.0.0',
          'Origin': 'https://iqbalbook.app',
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are an expert in Allama Iqbal's poetry and Islamic history. 
              Analyze the poem and provide details in a structured format.
              Do not include any Urdu text in your response, use English only.'''
            },
            {
              'role': 'user',
              'content': '''Analyze this poem by Allama Iqbal:
              Title: $cleanTitle
              Content: $content
              
              Provide information in this exact format:
              YEAR: [Approximate year or period when this poem was written]
              
              HISTORICAL CONTEXT:
              [Detailed explanation of historical events and circumstances during that period]
              
              SIGNIFICANCE:
              [Cultural and religious significance of the poem]
              
              Keep responses factual and in English only.'''
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Parse and clean the response
        final sections = content.split('\n\n');
        final year = _cleanText(sections[0].replaceAll('YEAR:', '').trim());
        final historicalContext = _cleanText(
            sections[1].replaceAll('HISTORICAL CONTEXT:', '').trim());
        final significance =
            _cleanText(sections[2].replaceAll('SIGNIFICANCE:', '').trim());

        return {
          'year': year,
          'historicalContext': historicalContext,
          'significance': significance,
        };
      }

      throw Exception('Failed to get response: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error in historical context analysis: $e');
      return {
        'year': 'Unknown',
        'historicalContext': 'Error retrieving historical context.',
        'significance': 'Error retrieving significance.',
      };
    }
  }

  // Add this helper method to clean text
  static String _cleanText(String text) {
    try {
      // Decode UTF-8
      final decoded = utf8.decode(utf8.encode(text));
      // Remove any remaining special characters
      return decoded.replaceAll(RegExp(r'[^\x00-\x7F\u0600-\u06FF\s]'), '');
    } catch (e) {
      debugPrint('Error cleaning text: $e');
      return text;
    }
  }

  static Future<String> analyzeHistoricalContext(String title) async {
    debugPrint('🔄 Starting analysis for: $title');

    try {
      final response = await http.post(
        Uri.parse('https://api.openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_openrouterKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/iqballiterature',
        },
        body: json.encode({
          'model': 'meta/llama-2-70b-chat',
          'messages': [
            {
              'role': 'user',
              'content': '''Please analyze this poem by Allama Iqbal:
              Title: "$title"
              
              Provide:
              1. Historical context and time period
              2. Political and social conditions
              3. Cultural significance
              4. Main themes and symbolism
              5. Impact on Islamic thought

              Keep response informative but concise.'''
            }
          ],
        }),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        debugPrint('✅ Received analysis');
        return content;
      }

      throw Exception('API Error: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ API Error: $e');
      throw Exception('Failed to analyze poem: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTimelineEvents({
    required String bookName,
    String? timePeriod,
  }) async {
    try {
      debugPrint('📊 Fetching timeline for book: $bookName');

      final response = await http.post(
        Uri.parse(_modelConfigs['primary']!['url'] as String),
        headers: {
          'Authorization': 'Bearer $_openrouterKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://iqbalbook.app',
          'X-Title': 'IqbalBook',
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a historian specializing in Allama Iqbal's works. 
              Create a timeline of events in JSON format. Use English text only, do not include Urdu or Persian text.'''
            },
            {
              'role': 'user',
              'content':
                  '''Create a timeline for Allama Iqbal's book "$bookName" 
              ${timePeriod != null ? 'during $timePeriod' : ''}.
              
              Return the response in this exact JSON format:
              [
                {
                  "year": "YYYY",
                  "title": "Event title (in English only)",
                  "description": "Detailed description (in English only)",
                  "significance": "Historical significance (in English only)"
                }
              ]
              
              Important:
              - Do not include any Urdu or Persian text
              - Transliterate any book names or terms into English
              - Include at least 5 significant events
              - Keep all text in English only'''
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];

        if (content == null) {
          throw Exception('Invalid API response format');
        }

        debugPrint('📝 Raw timeline response: $content');

        // Clean and parse the JSON string
        final cleanContent = _cleanText(content);
        final List<dynamic> events = jsonDecode(cleanContent);

        return events
            .map((event) => Map<String, dynamic>.from({
                  'year': _cleanText(event['year']?.toString() ?? ''),
                  'title': _cleanText(event['title']?.toString() ?? ''),
                  'description':
                      _cleanText(event['description']?.toString() ?? ''),
                  'significance':
                      _cleanText(event['significance']?.toString() ?? ''),
                }))
            .toList();
      }

      throw Exception('Failed to get timeline data: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Timeline Error: $e');
      return _getDefaultTimelineEvents();
    }
  }

  static List<Map<String, dynamic>> _getDefaultTimelineEvents() {
    return [
      {
        'year': '1877',
        'title': 'Birth of Allama Iqbal',
        'description': 'Allama Iqbal was born in Sialkot, Punjab.',
        'significance':
            'Beginning of a great poet and philosopher\'s life journey.'
      },
      {
        'year': '1930',
        'title': 'Famous Allahabad Address',
        'description': 'Iqbal delivered his presidential address at Allahabad.',
        'significance':
            'Presented the idea of a separate Muslim state in South Asia.'
      }
    ];
  }

  // Update the _cleanText method with advanced character handling
  static String _cleanTextEnhanced(String text) {
    try {
      // First decode UTF-8
      var decoded = utf8.decode(utf8.encode(text));

      // Replace common problematic characters
      var cleaned = decoded
          .replaceAll('Ø', '')
          .replaceAll('Ù', '')
          .replaceAll('Ø²', '')
          .replaceAll('Û', '')
          .replaceAll('Ø®', '')
          .replaceAll('Ø¯', '')
          .replaceAll('Ù¨', '')
          .replaceAll('�', '');

      // Remove any remaining non-ASCII characters except common punctuation
      return decoded.replaceAll(RegExp(r'[^\x20-\x7E\s.,!?()-]'), '');
    } catch (e) {
      debugPrint('Error cleaning text: $e');
      return text;
    }
  }
}

// Helper for retrying operations
Future<T> _retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 2,
  Duration delay = const Duration(seconds: 2),
}) async {
  var attempts = 0;
  while (attempts < maxAttempts) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts == maxAttempts) rethrow;
      await Future.delayed(delay * attempts);
    }
  }
  throw Exception('Max retry attempts reached');
}

// Add retry helper
Future<T> _tryWithRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 2,
  Duration delayBetween = const Duration(seconds: 2),
}) async {
  int attempts = 0;
  while (attempts < maxAttempts) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts == maxAttempts) rethrow;
      await Future.delayed(delayBetween);
    }
  }
  throw Exception('Max retry attempts reached');
}
