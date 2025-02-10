import 'package:hive/hive.dart';

class AnalysisCacheService {
  static const String _cacheBoxName = 'analysis_cache';
  static const String _rateLimitBoxName = 'rate_limit';
  late Box<String> _cacheBox;
  late Box<dynamic> _rateLimitBox;

  Future<void> init() async {
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _rateLimitBox = await Hive.openBox(_rateLimitBoxName);
  }

  Future<bool> canMakeRequest() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastResetDay = _rateLimitBox.get('lastResetDay');
    final requestCount = _rateLimitBox.get('requestCount') ?? 0;

    if (lastResetDay != today) {
      await _rateLimitBox.put('lastResetDay', today);
      await _rateLimitBox.put('requestCount', 0);
      return true;
    }

    return requestCount < 100;
  }

  Future<void> incrementRequestCount() async {
    final count = (_rateLimitBox.get('requestCount') ?? 0) + 1;
    await _rateLimitBox.put('requestCount', count);
  }

  Future<String?> getCachedAnalysis(String key) async {
    return _cacheBox.get(key);
  }

  Future<void> cacheAnalysis(String key, String analysis) async {
    await _cacheBox.put(key, analysis);
  }
}
