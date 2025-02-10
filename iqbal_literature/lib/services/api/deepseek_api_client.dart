import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DeepSeekApiClient {
  // Verify this endpoint with DeepSeek's documentation
  static const String baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String apiKey = 'sk-6ab4df9ffc434f89b9b41e06f0328a7e'; // Replace with valid key

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> analyze({
    required String prompt,
    int maxTokens = 2000,
    double temperature = 0.7,
  }) async {
    try {
      debugPrint('🚀 Request Prompt: $prompt');

      final messages = [
        {'role': 'system', 'content': 'You are an expert in Iqbal\'s poetry and Islamic history.'},
        {'role': 'user', 'content': prompt}
      ];

      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat', // Confirm correct model name
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception('API Error ${response.statusCode}: ${errorBody['error'] ?? 'Unknown error'}');
      }

      return _parseResponse(response.body);
    } catch (e) {
      debugPrint('❌ Critical API Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      
      // Validate response structure
      if (data['choices'] == null || 
          data['choices'].isEmpty || 
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