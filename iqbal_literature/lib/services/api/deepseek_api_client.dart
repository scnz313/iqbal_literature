import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DeepSeekApiClient {
  // Updated to a more reliable API endpoint with fallback model
  static const String baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String apiKey = 'sk-6ab4df9ffc434f89b9b41e06f0328a7e';
  static const String backupUrl = 'https://api.deepseek.ai/v1/chat/completions';
  static const String backupKey = 'sk-6ab4df9ffc434f89b9b41e06f0328a7e';

  final http.Client _client = http.Client();
  bool _usePrimaryEndpoint = true;

  Future<Map<String, dynamic>> analyze({
    required String prompt,
    int maxTokens = 2000,
    double temperature = 0.7,
  }) async {
    debugPrint('🚀 Request Prompt Length: ${prompt.length} chars');
    Exception? primaryError;

    // Try primary endpoint first
    if (_usePrimaryEndpoint) {
      try {
        return await _makeApiRequest(
            baseUrl, apiKey, prompt, maxTokens, temperature);
      } catch (e) {
        debugPrint('⚠️ Primary endpoint failed: $e');
        primaryError = e is Exception ? e : Exception(e.toString());
        _usePrimaryEndpoint = false; // Switch to backup for future calls
      }
    }

    // Try backup endpoint if primary fails
    try {
      return await _makeApiRequest(
          backupUrl, backupKey, prompt, maxTokens, temperature);
    } catch (e) {
      debugPrint('❌ Backup endpoint also failed: $e');

      // If we have both errors, provide more context
      if (primaryError != null) {
        throw Exception(
            'API requests failed. Primary: ${primaryError.toString()}, Backup: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _makeApiRequest(
    String url,
    String key,
    String prompt,
    int maxTokens,
    double temperature,
  ) async {
    final messages = [
      {
        'role': 'system',
        'content': 'You are an expert in Iqbal\'s poetry and Islamic history.'
      },
      {'role': 'user', 'content': prompt}
    ];

    final response = await _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    debugPrint('📡 Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          'API Error ${response.statusCode}: ${errorBody['error'] ?? 'Unknown error'}');
    }

    return _parseResponse(response.body);
  }

  Map<String, dynamic> _parseResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody);

      // Validate response structure
      if (data['choices'] == null ||
          data['choices'].isEmpty ||
          data['choices'][0]['message'] == null ||
          data['choices'][0]['message']['content'] == null) {
        throw FormatException('Invalid API response structure');
      }

      return data;
    } on FormatException catch (e) {
      debugPrint('🔧 Response Parsing Error: $e');
      rethrow;
    }
  }

  Future<String> getHistoricalContext(String title, [String? content]) async {
    try {
      final prompt = '''
      Analyze this poem by Allama Iqbal:
      Title: $title
      ${content != null ? 'Content: $content' : ''}

      Provide structured analysis including:
      1. Historical context of composition
      2. Key contemporary events
      3. Cultural/political influences
      4. Core philosophical themes
      5. Impact on Muslim renaissance''';

      final response = await analyze(prompt: prompt);
      return response['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('❌ Analysis Failed: $e');
      return 'Analysis unavailable. Error: ${e.toString().replaceAll(apiKey, '[REDACTED]')}';
    }
  }
}
