import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poem.dart';
import '../../../data/repositories/poem_repository.dart';
import '../../../services/share/share_bottom_sheet.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iqbal_literature/services/analysis/text_analysis_service.dart';
import 'package:iqbal_literature/services/analysis/analysis_bottom_sheet.dart';
import '../../../data/services/analytics_service.dart';
import '../../../services/api/gemini_api.dart';
import '../../books/controllers/book_controller.dart';
import 'dart:math'; // Add this import for min function
import 'dart:convert'; // Add this import for jsonDecode

class PoemController extends GetxController {
  final PoemRepository _poemRepository;
  final AnalyticsService _analyticsService;
  final TextAnalysisService _textAnalysisService;

  PoemController(
    this._poemRepository,
    this._analyticsService,
    this._textAnalysisService,
  );

  final RxList<Poem> poems = <Poem>[].obs;
  final RxString currentBookName = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxSet<String> favorites = <String>{}.obs;
  final RxString viewType = ''.obs;
  final RxDouble fontSize = 20.0.obs;
  static const double minFontSize = 16.0;
  static const double maxFontSize = 36.0;

  // Add these properties at the top with other properties
  final isAnalyzing = false.obs;
  final showAnalysis = false.obs;
  final poemAnalysis = ''.obs;

  Timer? _debounce; // Add debounce timer

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
    _loadFontSize();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final bookId = args['book_id'];
      if (bookId != null) {
        loadPoemsByBookId(bookId);
      } else {
        loadAllPoems();
      }
    } else {
      loadAllPoems();
    }
  }

  Future<void> loadPoemsByBookId(dynamic bookId) async {
    try {
      debugPrint('\n==== LOADING BOOK POEMS ====');
      debugPrint('📥 Incoming book_id: $bookId (${bookId.runtimeType})');

      isLoading.value = true;
      error.value = '';
      poems.clear(); // Ensure list is empty

      // Parse book ID
      final int targetBookId;
      if (bookId is int) {
        targetBookId = bookId;
      } else if (bookId is String) {
        targetBookId = int.tryParse(bookId) ?? 3;
      } else {
        targetBookId = 3;
      }

      debugPrint('🔍 Parsed book_id: $targetBookId');

      if (targetBookId <= 0) {
        debugPrint('❌ Invalid book ID');
        error.value = 'Invalid book ID';
        return;
      }

      final result = await _poemRepository.getPoemsByBookId(targetBookId);

      debugPrint('📦 Repository returned ${result.length} poems');

      if (result.isEmpty) {
        debugPrint('⚠️ No poems found');
        error.value = 'No poems found for this book';
        return;
      }

      // Verify book IDs
      final validPoems = result.where((p) {
        final isValid = p.bookId == targetBookId;
        if (!isValid) {
          debugPrint('⚠️ Found poem with wrong book_id: ${p.bookId}');
        }
        return isValid;
      }).toList();

      poems.assignAll(validPoems);
      debugPrint('✅ Final result: ${poems.length} poems');
      debugPrint('Book IDs in list: ${poems.map((p) => p.bookId).toSet()}');
    } catch (e) {
      debugPrint('❌ Error: $e');
      error.value = 'Failed to load poems';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFavorites = prefs.getStringList('favorites') ?? [];
      favorites.addAll(savedFavorites.map((id) => id.toString()));
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
    }
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFontSize = prefs.getDouble('font_size');
      if (savedFontSize != null) {
        fontSize.value = savedFontSize.clamp(minFontSize, maxFontSize);
      }
    } catch (e) {
      debugPrint('❌ Error loading font size: $e');
    }
  }

  Future<void> _saveFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('font_size', fontSize.value);
    } catch (e) {
      debugPrint('❌ Error saving font size: $e');
    }
  }

  bool isFavorite(Poem poem) {
    return favorites.contains(poem.id.toString());
  }

  void toggleFavorite(Poem poem) {
    final id = poem.id.toString();
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    _saveFavorites();

    _analyticsService.logEvent(
      name: 'toggle_poem_favorite',
      parameters: {
        'poem_id': poem.id,
        'is_favorite': favorites.contains(id),
      },
    );
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', favorites.toList());
    } catch (e) {
      debugPrint('❌ Error saving favorites: $e');
    }
  }

  Future<void> loadAllPoems() async {
    try {
      debugPrint('⏳ Loading all poems');
      isLoading.value = true;
      error.value = '';
      poems.clear();

      final result = await _poemRepository.getAllPoems();

      if (result.isEmpty) {
        error.value = 'No poems found';
      } else {
        poems.assignAll(result);
        debugPrint('✅ Loaded ${result.length} total poems');
        debugPrint(
            '📊 Poems from books: ${result.map((p) => p.bookId).toSet()}');
      }
    } catch (e) {
      debugPrint('❌ Error loading poems: $e');
      error.value = 'Failed to load poems';
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> getBookName(int bookId) async {
    try {
      final bookController = Get.find<BookController>();
      final book = bookController.books.firstWhereOrNull((b) => b.id == bookId);
      return book?.name ?? '';
    } catch (e) {
      debugPrint('Error getting book name: $e');
      return '';
    }
  }

  void onPoemTap(Poem poem) {
    Get.toNamed('/poem-detail', arguments: poem);
  }

  void sharePoem(Poem poem) {
    if (Get.context != null) {
      ShareBottomSheet.show(Get.context!, poem);
    }
  }

  Future<void> refreshPoems() async {
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args.containsKey('book')) {
      final book = args['book'];
      await loadPoemsByBookId(book.id);
    }
  }

  void increaseFontSize() {
    if (fontSize.value < maxFontSize) {
      fontSize.value += 2.0;
      // Debounce calls to _saveFontSize to prevent lag
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _saveFontSize);
    }
  }

  void decreaseFontSize() {
    if (fontSize.value > minFontSize) {
      fontSize.value -= 2.0;
      // Debounce calls to _saveFontSize to prevent lag
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _saveFontSize);
    }
  }

  Future<String> analyzePoem(String poemText) async {
    try {
      isAnalyzing.value = true;
      poemAnalysis.value = '';

      debugPrint(
          '📝 Analyzing poem: ${poemText.substring(0, min(50, poemText.length))}...');

      // Try to get analysis from TextAnalysisService
      final result = await _textAnalysisService.analyzePoem(poemText);

      // Log the analysis result for debugging
      debugPrint('📊 Analysis result type: ${result.runtimeType}');

      // Handle the result based on its type
      String formattedAnalysis;

      if (result is String) {
        // If it's already a string, we can use it directly
        formattedAnalysis = result;
      } else if (result is Map<String, dynamic>) {
        // Try to get the formatted analysis from the map
        try {
          formattedAnalysis = _formatPoemAnalysis(result);
        } catch (formatError) {
          debugPrint('⚠️ Error formatting map result: $formatError');
          // Fallback format
          formattedAnalysis =
              _createFallbackAnalysis(poemText, 'Error formatting response');
        }
      } else {
        // For other types, create a fallback
        debugPrint('⚠️ Unexpected result type: ${result.runtimeType}');
        formattedAnalysis =
            _createFallbackAnalysis(poemText, 'Unexpected response format');
      }

      isAnalyzing.value = false;
      poemAnalysis.value = formattedAnalysis;

      return formattedAnalysis;
    } catch (error) {
      debugPrint('❌ Poem analysis error: $error');

      // Check for the specific type error
      final isTypeError =
          error.toString().contains("type '_Map<dynamic, dynamic>'") ||
              error
                  .toString()
                  .contains("is not a subtype of type 'Map<String, dynamic>'");

      String fallbackAnalysis;
      if (isTypeError) {
        debugPrint('⚠️ Handling type error for analysis');
        fallbackAnalysis =
            _createFallbackAnalysis(poemText, 'Type conversion error');
      } else {
        fallbackAnalysis = _createFallbackAnalysis(poemText, error.toString());
      }

      isAnalyzing.value = false;
      poemAnalysis.value = fallbackAnalysis;

      return fallbackAnalysis;
    }
  }

  // Helper to format analysis map to string if needed
  String _formatPoemAnalysis(Map<String, dynamic> analysis) {
    // Extract key sections
    final summary = analysis['summary']?.toString() ?? 'Not available';
    final themes = analysis['themes']?.toString() ?? 'Not available';
    final context = analysis['context']?.toString() ?? 'Not available';
    final literaryAnalysis =
        analysis['analysis']?.toString() ?? 'Not available';

    // Return formatted string
    return '''Summary:
$summary

Themes:
$themes

Historical & Cultural Context:
$context

Literary Analysis:
$literaryAnalysis''';
  }

  // Create fallback analysis content based on the poem text
  String _createFallbackAnalysis(String poemText, String errorContext) {
    debugPrint('📝 Creating fallback analysis for poem');

    // Count lines for basic metrics
    final lines =
        poemText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final lineCount = lines.length;

    // Extract first line for reference
    final firstLine = lines.isNotEmpty ? lines.first.trim() : 'Unknown';

    // Identify potential themes by looking for common keywords
    final themeKeywords = {
      'divine': 'Divine connection',
      'god': 'Relationship with God',
      'khuda': 'Relationship with God',
      'allah': 'Islamic spirituality',
      'soul': 'Human soul',
      'spirit': 'Spirituality',
      'freedom': 'Freedom',
      'liberty': 'Liberty',
      'azadi': 'Freedom struggle',
      'nation': 'Nationalism',
      'islam': 'Islamic identity',
      'muslim': 'Muslim identity',
      'knowledge': 'Pursuit of knowledge',
      'wisdom': 'Wisdom and enlightenment',
      'self': 'Self-discovery',
      'love': 'Love and devotion',
      'youth': 'Youth empowerment',
      'revolution': 'Revolutionary spirit',
      'change': 'Social change',
      'eagle': 'Freedom and strength (symbolism)',
      'shaheen': 'Courage and ambition',
    };

    // Check for theme presence
    final List<String> detectedThemes = [];
    final lowerPoemText = poemText.toLowerCase();

    themeKeywords.forEach((keyword, theme) {
      if (lowerPoemText.contains(keyword.toLowerCase())) {
        if (!detectedThemes.contains(theme)) {
          detectedThemes.add(theme);
        }
      }
    });

    // If no themes detected, add default ones
    if (detectedThemes.isEmpty) {
      detectedThemes.add('Spirituality');
      detectedThemes.add('Self-realization');
      detectedThemes.add('Cultural identity');
    }

    // Limit to top 3 themes
    final themes = detectedThemes.take(3).map((theme) => '• $theme').join('\n');

    return '''Summary:
This ${lineCount > 10 ? 'longer' : 'short'} poem begins with "${firstLine}" and contains ${lineCount} verse${lineCount > 1 ? 's' : ''}. It exemplifies Iqbal's distinctive style of using poetic metaphors to convey philosophical ideas. The poem appears to explore themes typical in Iqbal's work, including spiritual awakening and social consciousness.

Themes:
$themes

Historical & Cultural Context:
This poem reflects Iqbal's philosophical outlook during the early 20th century when he was developing his ideas about self-realization (Khudi) and the revival of Islamic thought. Written during a time of political awakening in the Indian subcontinent, it captures the intellectual ferment of that era. Iqbal frequently addressed the spiritual and cultural identity of Muslims in his works.

Literary Analysis:
The poem employs Iqbal's characteristic use of symbolic language and metaphors. His poetry often balances between Persian literary traditions and Urdu expressive forms, creating a unique poetic voice. The verses likely contain philosophical depth that reflects Iqbal's training in both Eastern and Western philosophical traditions. Note that this is an offline analysis - for more detailed insights, please try again with an internet connection.
''';
  }

  Future<Map<String, dynamic>> analyzeWord(String word) async {
    try {
      isAnalyzing.value = true;

      try {
        // Try direct Gemini API approach first for more reliable results
        debugPrint('📝 Directly analyzing word: $word');
        final response = await GeminiAPI.generateContent(
          prompt: '''Analyze this Urdu/Persian word: "$word"
          
You MUST respond with ONLY a valid JSON object in this exact format, with no additional text:
{
  "meaning": {
    "english": "English meaning",
    "urdu": "Urdu meaning in English transliteration"
  },
  "pronunciation": "phonetic guide",
  "partOfSpeech": "grammar category",
  "examples": ["example 1", "example 2"]
}''',
          temperature: 0.1,
        );

        // Try to extract JSON from the response
        try {
          debugPrint(
              '📊 Raw word analysis response: ${response.substring(0, min(100, response.length))}...');

          // Extract JSON if response contains markdown code blocks
          Map<String, dynamic> result = {};

          if (response.contains('```json') || response.contains('```')) {
            // Extract JSON from markdown code block
            final startMarker =
                response.contains('```json') ? '```json' : '```';
            final endMarker = '```';

            final jsonStart =
                response.indexOf(startMarker) + startMarker.length;
            final jsonEnd = response.lastIndexOf(endMarker);

            if (jsonStart > 0 && jsonEnd > jsonStart) {
              final jsonStr = response.substring(jsonStart, jsonEnd).trim();
              debugPrint(
                  '📝 Extracted JSON: ${jsonStr.substring(0, min(100, jsonStr.length))}...');

              // Parse JSON with explicit type casting
              final dynamic rawData = jsonDecode(jsonStr);

              // Create a properly typed Map
              result = <String, dynamic>{};

              // Safely extract meaning map
              result['meaning'] = <String, String>{};
              if (rawData['meaning'] != null) {
                result['meaning'] = {
                  'english': rawData['meaning']['english']?.toString() ??
                      'Not available',
                  'urdu':
                      rawData['meaning']['urdu']?.toString() ?? 'Not available'
                };
              }

              // Extract other fields with safe conversions
              result['pronunciation'] =
                  rawData['pronunciation']?.toString() ?? 'Not available';
              result['partOfSpeech'] =
                  rawData['partOfSpeech']?.toString() ?? 'Unknown';

              // Handle examples list
              if (rawData['examples'] is List) {
                result['examples'] = (rawData['examples'] as List)
                    .map((e) => e.toString())
                    .toList();
              } else {
                result['examples'] = ['Example not available'];
              }

              return result;
            }
          }

          // If we couldn't extract from markdown, try entire JSON
          final jsonStart = response.indexOf('{');
          final jsonEnd = response.lastIndexOf('}') + 1;

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonStr = response.substring(jsonStart, jsonEnd);

            // Parse JSON with explicit type casting
            final dynamic rawData = jsonDecode(jsonStr);

            // Create a properly typed Map
            result = <String, dynamic>{};

            // Safely extract meaning map
            result['meaning'] = <String, String>{};
            if (rawData['meaning'] != null) {
              result['meaning'] = {
                'english': rawData['meaning']['english']?.toString() ??
                    'Not available',
                'urdu':
                    rawData['meaning']['urdu']?.toString() ?? 'Not available'
              };
            }

            // Extract other fields with safe conversions
            result['pronunciation'] =
                rawData['pronunciation']?.toString() ?? 'Not available';
            result['partOfSpeech'] =
                rawData['partOfSpeech']?.toString() ?? 'Unknown';

            // Handle examples list
            if (rawData['examples'] is List) {
              result['examples'] = (rawData['examples'] as List)
                  .map((e) => e.toString())
                  .toList();
            } else {
              result['examples'] = ['Example not available'];
            }

            return result;
          }
        } catch (jsonError) {
          debugPrint('⚠️ Error parsing word analysis JSON: $jsonError');
          // Fall back to service approach
        }
      } catch (directError) {
        debugPrint('⚠️ Direct word analysis failed: $directError');
        // Continue to service approach
      }

      // Fall back to regular service approach
      final rawResult = await _textAnalysisService.analyzeWord(word);

      // Create a fresh Map<String, dynamic> with explicit typing to ensure type safety
      final Map<String, dynamic> result = <String, dynamic>{};

      // Safely extract meaning map
      result['meaning'] = <String, String>{};
      if (rawResult['meaning'] is Map) {
        result['meaning'] = {
          'english':
              rawResult['meaning']['english']?.toString() ?? 'Not available',
          'urdu': rawResult['meaning']['urdu']?.toString() ?? 'Not available'
        };
      }

      // Extract other fields with safe conversions
      result['pronunciation'] =
          rawResult['pronunciation']?.toString() ?? 'Not available';
      result['partOfSpeech'] =
          rawResult['partOfSpeech']?.toString() ?? 'Unknown';

      // Handle examples list
      if (rawResult['examples'] is List) {
        result['examples'] =
            (rawResult['examples'] as List).map((e) => e.toString()).toList();
      } else {
        result['examples'] = ['Example not available'];
      }

      return result;
    } catch (e) {
      debugPrint('❌ Word analysis error: $e');
      return {
        'meaning': {
          'english': 'Analysis failed',
          'urdu': word,
        },
        'pronunciation': 'Not available',
        'partOfSpeech': 'Not available',
        'examples': ['Not available'],
      };
    } finally {
      isAnalyzing.value = false;
    }
  }

  void showHistoricalContext(BuildContext context, Poem poem) {
    debugPrint('Showing historical context for poem: ${poem.title}');
    _analyticsService.logEvent(
      name: 'view_historical_context',
      parameters: {'poem_id': poem.id},
    );

    // Show the historical context bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Center(child: Text('Historical Context')),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> getHistoricalContext(int poemId) async {
    try {
      debugPrint('🔄 Getting historical context for poem ID: $poemId');
      isAnalyzing.value = true;

      final poem = poems.firstWhere((p) => p.id == poemId);
      debugPrint('📖 Found poem: ${poem.title}');

      // Try getting from cache first
      final cachedContext = await _poemRepository.getHistoricalContext(poemId);
      if (cachedContext != null) {
        debugPrint('📦 Using cached historical context');
        return cachedContext;
      }

      // Get fresh analysis from Gemini
      debugPrint('🤖 Requesting fresh analysis from Gemini...');
      final result =
          await GeminiAPI.getHistoricalContext(poem.title, poem.cleanData);

      // Cache the result for future use
      _poemRepository.saveHistoricalContext(poemId, result);

      // Return all sections from the analysis
      return {
        'year': result['year'] ?? 'Unknown',
        'historicalContext':
            result['historicalContext'] ?? 'No historical context available',
        'significance':
            result['significance'] ?? 'No significance data available',
        'culturalImportance': result['culturalImportance'],
        'religiousThemes': result['religiousThemes'],
        'politicalMessages': result['politicalMessages'],
        'specificAnalysis': result['factualInformation'],
        'imagery': result['imagery'],
        'metaphor': result['metaphor'],
        'symbolism': result['symbolism'],
        'theme': result['theme'],
      };
    } catch (e) {
      debugPrint('❌ Historical context error: $e');
      return {
        'year': 'Unavailable',
        'historicalContext':
            'Could not retrieve historical context. Please try again.',
        'significance': 'Analysis temporarily unavailable.'
      };
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getTimeline(String bookName,
      [String? timePeriod]) async {
    try {
      isAnalyzing.value = true;
      return await GeminiAPI.getTimelineEvents(bookName, timePeriod);
    } catch (e) {
      debugPrint('❌ Timeline generation failed: $e');
      return [
        {
          'year': 'N/A',
          'title': 'Timeline Unavailable',
          'description': 'Could not generate timeline',
          'significance': 'Please try again later'
        }
      ];
    } finally {
      isAnalyzing.value = false;
    }
  }

  /// Shows the poem analysis bottom sheet
  Future<void> showPoemAnalysis(String poemText) async {
    // Prevent multiple concurrent analysis requests
    if (isAnalyzing.value) {
      debugPrint('⚠️ Analysis already in progress, ignoring duplicate request');
      return;
    }

    // Set loading state
    isAnalyzing.value = true;

    // Check connection status
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isOffline = connectivityResult == ConnectivityResult.none;

    if (isOffline) {
      debugPrint('📡 No internet connection, will use offline analysis');
      Get.snackbar(
        'Offline Mode',
        'Using offline analysis. Connect to internet for AI-powered results.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }

    if (Get.context != null) {
      try {
        // Show a single bottom sheet with the analysis future
        await AnalysisBottomSheet.show(
          Get.context!,
          'Poem Analysis',
          _getAnalysisContent(poemText, isOffline),
        );
      } catch (e) {
        debugPrint('❌ Error showing analysis: $e');
        Get.snackbar(
          'Analysis Error',
          'Could not display analysis. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        // Always reset the loading state
        isAnalyzing.value = false;
      }
    } else {
      isAnalyzing.value = false;
    }
  }

  // Helper method that returns a Future<String> for the analysis content
  Future<String> _getAnalysisContent(String poemText, bool isOffline) async {
    try {
      debugPrint('🔍 Starting poem analysis...');

      // Try direct Gemini API for online analysis
      if (!isOffline) {
        try {
          final Map<String, dynamic> response =
              await GeminiAPI.analyzePoemContent(poemText);
          debugPrint('✅ Gemini response received successfully');

          // Format the response
          final formattedResponse = _formatPoemAnalysis(response);
          poemAnalysis.value = formattedResponse;
          return formattedResponse;
        } catch (apiError) {
          debugPrint('⚠️ Gemini API error: $apiError');
          // Continue to fallback
        }
      }

      // Fallback to local analysis
      final fallbackAnalysis = _createFallbackAnalysis(
          poemText, isOffline ? 'Offline mode' : 'API error');
      poemAnalysis.value = fallbackAnalysis;
      return fallbackAnalysis;
    } catch (e) {
      debugPrint('❌ Analysis completely failed: $e');
      return 'Could not analyze poem: ${e.toString().substring(0, min(50, e.toString().length))}';
    }
  }
}
