import '../api/deepseek_api_client.dart';
import '../cache/analysis_cache_service.dart';

class TextAnalysisService {
  final DeepSeekApiClient _apiClient;
  final AnalysisCacheService _cacheService;

  TextAnalysisService(this._apiClient, this._cacheService);

  Future<String> analyzeWord(String word) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached (100 requests)');
    }

    final cacheKey = 'word_$word';
    final cachedResult = await _cacheService.getCachedAnalysis(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }

    final prompt = '''
    Analyze the word "$word" and provide:
    1. Meaning in English and Urdu
    2. Pronunciation
    3. Part of speech
    4. Usage examples
    ''';

    final response = await _apiClient.analyze(prompt: prompt);
    final analysis = response['choices'][0]['message']['content'];
    
    await _cacheService.cacheAnalysis(cacheKey, analysis);
    await _cacheService.incrementRequestCount();
    
    return analysis;
  }

  Future<String> analyzePoem(String poem) async {
    if (!await _cacheService.canMakeRequest()) {
      throw Exception('Daily API limit reached (100 requests)');
    }

    final cacheKey = 'poem_${poem.hashCode}';
    final cachedResult = await _cacheService.getCachedAnalysis(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }

    final prompt = '''
    Analyze this poem and provide:
    1. Summary
    2. Main themes
    3. Cultural context
    4. Literary devices used
    
    Poem:
    $poem
    ''';

    final response = await _apiClient.analyze(prompt: prompt);
    final analysis = response['choices'][0]['message']['content'];
    
    await _cacheService.cacheAnalysis(cacheKey, analysis);
    await _cacheService.incrementRequestCount();
    
    return analysis;
  }
}
