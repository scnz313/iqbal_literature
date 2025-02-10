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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
            'stopSequences': ['```'],
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (content == null) {
          throw Exception('Invalid response format from Gemini API');
        }

        return content.toString().trim();
      }

      throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
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
        .replaceAll(''', "'")
        .trim();
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

  static Future<List<Map<String, dynamic>>> getTimelineEvents(
    String bookName, 
    [String? timePeriod]
  ) async {
    if (!isConfigured) {
      throw Exception('Gemini API not configured');
    }

    try {
      debugPrint('📝 Requesting timeline from Gemini...');
      final response = await generateContent(
        prompt: _getTimelinePrompt(bookName),
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
          .replaceAll(RegExp(r'[\u2018\u2019\u201C\u201D]'), '"') // Smart quotes
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
      debugPrint('❌ JSON cleaning failed: $e');
      return null;
    }
  }

  static String _getTimelinePrompt(String bookName) {
    return '''As an expert on Allama Iqbal's literary works, create a detailed historical timeline for "$bookName".
Provide exactly 5 significant events formatted as a JSON array.

For each event include:
1. Year - Specific date if known
2. Title - Clear, descriptive title of the event
3. Description - 3-4 sentences covering:
   - Historical context and background
   - Key figures involved
   - Cultural and literary significance
   - Impact on Iqbal's work
4. Significance - 3-4 sentences explaining:
   - Literary importance
   - Historical relevance
   - Cultural impact
   - Connection to Iqbal's philosophy

Format Example:
[
  {
    "year": "1915",
    "title": "Publication of Asrar-e-Khudi",
    "description": "First Persian masterwork published in Lahore. The work introduced Iqbals philosophical vision to a wider audience. Notable scholars and intellectuals praised its innovative approach to Islamic thought.",
    "significance": "Established Iqbal as a major philosophical poet. The work influenced Muslim intellectual discourse throughout the subcontinent. Its themes of self-realization continue to resonate today."
  }
]

IMPORTANT:
- Provide extensive factual details
- Use simple ASCII characters only
- Avoid quotes within text
- Keep sentences clear and complete
- Focus on historical accuracy
- Maintain valid JSON structure''';
  }

  static List<Map<String, dynamic>> _getDefaultTimelineEvents(String bookName) {
    return [
      {
        'year': '1915',
        'title': 'First Publication',
        'description': 'The work was first published in Lahore during a pivotal time in Indian history. Muslim intellectual movements were gaining momentum across the subcontinent. The publication coincided with growing calls for political and social reform.',
        'significance': 'Marked a significant development in Urdu/Persian literature. The work influenced both literary and political discourse. Its themes resonated with the emerging Muslim consciousness of the era.',
      },
      {
        'year': '1920',
        'title': 'Critical Reception and Impact',
        'description': 'Major literary figures and scholars began analyzing and commenting on the work. It sparked intellectual debates across academic circles. The themes and ideas presented challenged conventional thinking.',
        'significance': 'Established new directions in philosophical poetry. Generated important discussions about Muslim identity and progress. Influenced subsequent generations of writers and thinkers.',
      },
      // ...more detailed default events...
    ];
  }

  static String _cleanJsonResponse(String response) {
    // First, extract the JSON array
    final jsonStart = response.indexOf('[');
    final jsonEnd = response.lastIndexOf(']') + 1;
    
    if (jsonStart < 0 || jsonEnd <= jsonStart) {
      throw Exception('Invalid JSON format in response');
    }

    var cleanedJson = response
        .substring(jsonStart, jsonEnd)
        // Replace all single quotes with double quotes for JSON
        .replaceAll("'", '"')
        // Clean other special characters
        .replaceAll('–', '-')
        .replaceAll('…', '...')
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll(' ', ' ') // Replace special spaces
        .replaceAll(RegExp(r'[^\x20-\x7E\s]'), '');

    // Format the JSON properly
    try {
      // Test parse to ensure valid JSON
      final parsed = jsonDecode(cleanedJson);
      return jsonEncode(parsed); // Re-encode to ensure proper formatting
    } catch (e) {
      debugPrint('First JSON parse failed, trying additional cleaning...');
      
      // Additional cleaning attempt
      cleanedJson = cleanedJson
          .replaceAll(RegExp(r'\\(?!["\\/bfnrt])'), '')
          .replaceAll(RegExp(r',(\s*[}\]])', multiLine: true), r'$1');

      try {
        final parsed = jsonDecode(cleanedJson);
        return jsonEncode(parsed);
      } catch (e) {
        debugPrint('❌ JSON cleaning failed: $e');
        throw Exception('Could not clean JSON response');
      }
    }
  }

  static String _cleanTextContent(String text) {
    return text
        .replaceAll('"', "'")
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('"', "'")
        .replaceAll('"', "'")
        .replaceAll('\\', '')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .trim();
  }

  static String _cleanString(String text) {
    return text
        .replaceAll('"', "'")
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('"', "'")
        .replaceAll('"', "'")
        .trim();
  }

  static Future<Map<String, String>> getHistoricalContext(String title, String content) async {
    if (!isConfigured) {
      throw Exception('Gemini API not configured');
    }

    final prompt = '''You are a scholar of Allama Iqbal's poetry. Analyze this Urdu/Persian poem:

Title: $title
Content: $content

Provide a detailed analysis focusing on these aspects. Be specific and factual:

YEAR:
Write when this poem was written. If exact year unknown, give approximate range based on Iqbal's life periods (1877-1938).

HISTORICAL_CONTEXT:
Describe the historical events, political climate, and social circumstances when this poem was written. Consider both the Indian subcontinent and global context.

SIGNIFICANCE:
Explain the poem's cultural importance, religious themes, and political messages in Iqbal's broader philosophy.

Note: You must provide substantive information for each section based on your knowledge of Iqbal's work and historical context.''';

    try {
      debugPrint('🔄 Requesting historical context for: $title');
      String response = await generateContent(
        prompt: prompt,
        temperature: 0.3,
      );

      // Retry with more specific prompt if first attempt fails
      if (_isGenericResponse(response)) {
        debugPrint('⚠️ Received generic response, retrying with enhanced prompt...');
        response = await _retryWithEnhancedPrompt(title, content);
      }

      debugPrint('📝 Raw response: $response');

      final result = _parseHistoricalContextResponse(response);

      // Validate content is meaningful
      if (_isInvalidContent(result)) {
        throw Exception('Insufficient analysis generated');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Historical context error: $e');
      throw Exception('Failed to analyze historical context');
    }
  }

  static bool _isGenericResponse(String response) {
    final genericPhrases = [
      'not provided in the context',
      'no information',
      'cannot be determined',
      'is not available',
      'no historical context',
    ];

    return genericPhrases.any((phrase) => 
      response.toLowerCase().contains(phrase.toLowerCase()));
  }

  static Future<String> _retryWithEnhancedPrompt(String title, String content) async {
    final enhancedPrompt = '''As an expert on Allama Iqbal's poetry and Islamic philosophy, analyze this poem:

Title: $title
Content: $content

Drawing from your knowledge of Iqbal's life (1877-1938), his philosophical development, and historical events:

1. YEAR:
- Consider when similar themes appeared in his work
- Look at the poetic style and language usage
- Reference related poems from the same period

2. HISTORICAL_CONTEXT:
- What was happening in British India?
- What were the major Muslim intellectual movements?
- How does this connect to Iqbal's philosophy?

3. SIGNIFICANCE:
- How does this poem reflect Iqbal's core messages?
- What Islamic concepts are referenced?
- How does it relate to his vision for Muslim society?

Provide specific details for each section. Avoid generic responses.''';

    return await generateContent(
      prompt: enhancedPrompt,
      temperature: 0.7,
      maxTokens: 1500,
    );
  }

  static bool _isInvalidContent(Map<String, String> result) {
    // More lenient validation
    if (result.isEmpty) return true;
    
    // Check if all values are default "not available" messages
    if (result.values.every((v) => v.contains('not available'))) return true;

    // Check for minimum content length in any section
    return !result.values.any((value) => 
      value.length > 20 && 
      !value.contains('not available') &&
      !value.contains('Information not available')
    );
  }

  static void _updateSection(Map<String, String> result, String section, String content) {
    final cleaned = content.trim();
    if (cleaned.isNotEmpty) {
      result[section] = cleaned;
    }
  }

  static String _sanitizeUrduText(String text) {
    // Convert Urdu numerals to English
    final numericMap = {
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9'
    };
    
    return text
        .split('')
        .map((char) => numericMap[char] ?? char)
        .join('')
        .replaceAll(RegExp(r'[^\x00-\x7F\s۰-۹آ-ی]'), '') // Keep Urdu, numbers, and basic ASCII
        .trim();
  }

  static Map<String, String> _parseHistoricalContextResponse(String response) {
    final result = <String, String>{};
    
    try {
      // Clean response of markdown and formatting
      final cleanedResponse = response
          .replaceAll('**', '')
          .replaceAll('*', '')
          .trim();

      // Extract main sections
      String currentSection = '';
      StringBuffer contentBuffer = StringBuffer();

      for (final line in cleanedResponse.split('\n')) {
        final trimmed = line.trim();
        
        if (trimmed.isEmpty) {
          if (currentSection.isNotEmpty) {
            result[currentSection] = contentBuffer.toString().trim();
            contentBuffer.clear();
          }
          continue;
        }

        // Update section detection logic
        if (trimmed.startsWith('YEAR:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'year';
          contentBuffer.clear();
        } else if (trimmed.startsWith('HISTORICAL_CONTEXT:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'historicalContext';
          contentBuffer.clear();
        } else if (trimmed.startsWith('SIGNIFICANCE:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'significance';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Cultural Importance:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'culturalImportance';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Religious Themes:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'religiousThemes';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Political Messages:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'politicalMessages';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Specific')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'factualInformation';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Imagery:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'imagery';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Metaphor:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'metaphor';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Symbolism:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'symbolism';
          contentBuffer.clear();
        } else if (trimmed.startsWith('Theme:')) {
          _updateSection(result, currentSection, contentBuffer.toString());
          currentSection = 'theme';
          contentBuffer.clear();
        } else if (currentSection.isNotEmpty) {
          if (contentBuffer.isNotEmpty) {
            contentBuffer.write('\n');
          }
          contentBuffer.write(trimmed);
        }
      }

      // Add final section content
      if (currentSection.isNotEmpty) {
        result[currentSection] = contentBuffer.toString().trim();
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error parsing response: $e');
      return {
        'year': 'Year not available',
        'historicalContext': 'Historical context not available',
        'significance': 'Significance not available',
      };
    }
  }

  static void _addToResult(Map<String, String> result, String section, String content) {
    final cleaned = content
        .trim()
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // Remove extra newlines
        .replaceAll(RegExp(r'\*+'), '') // Remove asterisks
        .replaceAll(RegExp(r'^\s*[-•]\s*'), '') // Remove list markers
        .trim();
        
    if (cleaned.isNotEmpty) {
      result[section] = cleaned;
    }
  }

  static bool _isValidHistoricalContext(Map<String, String> context) {
    return context.values.every((value) => 
      value.isNotEmpty && 
      value != 'Not available' &&
      value.length > 10
    );
  }

  static void _addSectionContent(Map<String, String> result, String section, String content) {
    final cleaned = content.trim();
    if (cleaned.isNotEmpty) {
      result[section] = cleaned;
    }
  }

  static String _extractSection(List<String> sections, String header) {
    final section = sections.firstWhere(
      (s) => s.trim().startsWith(header),
      orElse: () => '$header Not available',
    );
    return section.replaceFirst(header, '').trim();
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