import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../features/poems/models/poem.dart';
import '../../../data/repositories/poem_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../services/analysis/text_analysis_service.dart';
import '../../../services/share/share_bottom_sheet.dart';
import '../../../services/api/gemini_api.dart';
import '../../books/controllers/book_controller.dart';
import '../../../services/analysis/analysis_bottom_sheet.dart';

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

  void _processArguments() {
    debugPrint('\n==== PROCESSING NAVIGATION ARGS ====');
    final args = Get.arguments;
    
    if (args == null) {
      debugPrint('❌ No arguments received - loading all poems');
      loadAllPoems();  // Changed to load all poems
      return;
    }

    if (args is! Map<String, dynamic>) {
      debugPrint('❌ Arguments not a Map - loading all poems');
      loadAllPoems();  // Changed to load all poems
      return;
    }

    final bookId = args['book_id'];
    final bookName = args['book_name']?.toString();
    final viewType = args['view_type']?.toString();

    // Reset state
    poems.clear();
    currentBookName.value = bookName ?? '';
    this.viewType.value = viewType ?? '';
    error.value = '';

    if (bookId != null && viewType == 'book_specific') {
      debugPrint('✅ Loading book-specific poems');
      loadPoemsByBookId(bookId);
    } else {
      debugPrint('ℹ️ Loading all poems');
      loadAllPoems();  // Changed to load all poems
    }
  }

  Future<void> loadPoemsByBookId(dynamic bookId) async {
    try {
      debugPrint('\n==== LOADING BOOK POEMS ====');
      debugPrint('📥 Incoming book_id: $bookId (${bookId.runtimeType})');
      
      isLoading.value = true;
      error.value = '';
      poems.clear();  // Ensure list is empty

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
        debugPrint('📊 Poems from books: ${result.map((p) => p.bookId).toSet()}');
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

  Future<void> analyzePoem(String text) async {
    // Prevent multiple simultaneous analyses
    if (isAnalyzing.value) {
      debugPrint('⚠️ Analysis already in progress, skipping...');
      return;
    }

    try {
      isAnalyzing.value = true;

      if (Get.context != null) {
        // Remove any existing bottom sheets first
        Navigator.of(Get.context!).popUntil((route) => route is! ModalBottomSheetRoute);
        
        await AnalysisBottomSheet.show(
          Get.context!, 
          'Poem Analysis',
          Future(() async {
            try {
              final analysis = await _textAnalysisService.analyzePoem(text);
              return analysis;
            } catch (e) {
              debugPrint('❌ Analysis error: $e');
              throw Exception('Failed to analyze poem. Please try again.');
            }
          }),
        );
      }
    } catch (e) {
      debugPrint('❌ Analysis error: $e');
      Get.snackbar(
        'Error',
        'Failed to analyze poem. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<Map<String, dynamic>> analyzeWord(String word) async {
    try {
      isAnalyzing.value = true;
      return await _textAnalysisService.analyzeWord(word);
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
      final result = await GeminiAPI.getHistoricalContext(poem.title, poem.cleanData);
      
      // Cache the result for future use
      _poemRepository.saveHistoricalContext(poemId, result);
      
      // Return all sections from the analysis
      return {
        'year': result['year'] ?? 'Unknown',
        'historicalContext': result['historicalContext'] ?? 'No historical context available',
        'significance': result['significance'] ?? 'No significance data available',
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
        'historicalContext': 'Could not retrieve historical context. Please try again.',
        'significance': 'Analysis temporarily unavailable.'
      };
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getTimeline(String bookName, [String? timePeriod]) async {
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
}
