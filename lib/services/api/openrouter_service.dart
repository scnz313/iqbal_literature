import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenRouterService {
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> analyzePoem(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://iqbalbook.app',
          'X-Title': 'IqbalBook',
          'User-Agent': 'IqbalBook/1.0.0',
          'Origin': 'https://iqbalbook.app'
        },
        body: jsonEncode({
          "model": "openai/gpt-3.5-turbo",
          "temperature": 0.7,
          "max_tokens": 1000,
          "top_p": 1,
          "messages": [
            {
              "role": "system",
              "content": """You are a literary expert specializing in Urdu and Persian poetry analysis.
              Provide analysis in this exact format:

              SUMMARY
              [2-3 sentences in English]

              THEMES
              • [Theme 1]
              • [Theme 2]
              • [Theme 3]

              CONTEXT
              [2-3 sentences about cultural/historical context]

              ANALYSIS
              • [Key point 1]
              • [Key point 2]
              • [Key point 3]
              
              Keep all responses in English only."""
            },
            {
              "role": "user",
              "content": "Analyze this poem:\n\n$text"
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        
        if (content == null || content.toString().isEmpty) {
          throw 'No analysis generated';
        }
        
        return _formatAnalysis(content);
      } else {
        throw 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Analysis Error: $e');
      rethrow;
    }
  }

  static String _formatAnalysis(String content) {
    // Split sections and format them
    final sections = content.split('\n\n');
    final formattedSections = sections.map((section) {
      final lines = section.split('\n');
      if (lines.isEmpty) return '';
      
      // Format bullet points
      return lines.map((line) {
        if (line.startsWith('•')) {
          return '  $line';
        }
        return line;
      }).join('\n');
    }).join('\n\n');

    return formattedSections;
  }

  static Future<Map<String, dynamic>> analyzeWord(String word) async {
    try {
      debugPrint('Analyzing word: $word');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://iqbalbook.app',
          'X-Title': 'IqbalBook',
          'User-Agent': 'IqbalBook/1.0.0',
          'Origin': 'https://iqbalbook.app'
        },
        body: jsonEncode({
          "model": "openai/gpt-3.5-turbo",
          "temperature": 0.7,
          "max_tokens": 500,
          "messages": [
            {
              "role": "system",
              "content": "You are a linguistics expert. Analyze Urdu/Persian words and return JSON format responses."
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
          ]
        }),
      );

      debugPrint('Word Analysis Response Status: ${response.statusCode}');
      debugPrint('Word Analysis Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        
        if (content == null || content.toString().isEmpty) {
          throw 'No analysis generated';
        }

        try {
          return jsonDecode(content);
        } catch (e) {
          debugPrint('JSON parsing error: $e');
          debugPrint('Raw content: $content');
          return {
            'meaning': {
              'english': content,
              'urdu': word
            },
            'pronunciation': 'Not available',
            'partOfSpeech': 'Not available',
            'examples': ['Not available']
          };
        }
      } else {
        throw 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Word Analysis Error: $e');
      rethrow;
    }
  }
}
