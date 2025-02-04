import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekApiClient {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  static const String apiKey = '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';

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> analyze({required String prompt}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://iqbalbook.app',
          'X-Title': 'IqbalBook',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-r1:free',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to DeepSeek API: $e');
    }
  }
}
