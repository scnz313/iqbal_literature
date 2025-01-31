import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/poem/poem.dart';
import '../../../data/repositories/poem_repository.dart';
import '../../../data/services/analytics_service.dart';

class PoemController extends GetxController {
  final PoemRepository _poemRepository;
  final AnalyticsService _analyticsService;

  PoemController(this._poemRepository, this._analyticsService);

  final RxList<Poem> poems = <Poem>[].obs;
  final RxString currentBookName = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxSet<String> favorites = <String>{}.obs;
  final RxString viewType = ''.obs;
  final RxDouble fontSize = 20.0.obs;  // Default font size
  static const double minFontSize = 16.0;
  static const double maxFontSize = 36.0;

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
    _loadFontSize();  // Add this line
    
    debugPrint('=== POEM CONTROLLER INIT ===');
    final args = Get.arguments;
    debugPrint('📥 Arguments received: $args');
    
    if (args != null && args is Map<String, dynamic>) {
      final bookId = args['book_id'];
      final bookName = args['book_name'];
      final viewType = args['view_type'];
      
      debugPrint('📄 Parsed arguments:');
      debugPrint('- Book ID: $bookId (${bookId?.runtimeType})');
      debugPrint('- Book Name: $bookName');
      debugPrint('- View Type: $viewType');
      
      currentBookName.value = bookName ?? '';
      viewType.value = viewType ?? '';

      if (bookId != null && viewType == 'book_specific') {
        loadPoemsByBookId(bookId);
      } else {
        loadAllPoems();
      }
    } else {
      debugPrint('❌ No arguments - defaulting to all poems');
      loadAllPoems();
    }
  }

  Future<void> _loadFavorites() async {
    // Load favorites from local storage
    final prefs = await SharedPreferences.getInstance();
    final savedFavorites = prefs.getStringList('favorites') ?? [];
    favorites.addAll(savedFavorites);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFontSize = prefs.getDouble('font_size');
    if (savedFontSize != null) {
      fontSize.value = savedFontSize.clamp(minFontSize, maxFontSize);
    }
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', fontSize.value);
  }

  bool isFavorite(Poem poem) => favorites.contains(poem.id);

  void toggleFavorite(Poem poem) {
    if (isFavorite(poem)) {
      favorites.remove(poem.id);
    } else {
      favorites.add(poem.id);
    }
    _saveFavorites();
  }

  void _debugPrintBookInfo(int bookId, List<Poem> poems) {
    debugPrint('📊 Book Poems Debug Info:');
    debugPrint('Book ID: $bookId');
    debugPrint('Total poems found: ${poems.length}');
    debugPrint('Unique book IDs in results: ${poems.map((p) => p.bookId).toSet()}');
    if (poems.isNotEmpty) {
      debugPrint('First poem info:');
      debugPrint('- Title: ${poems.first.title}');
      debugPrint('- Book ID: ${poems.first.bookId}');
    }
  }

  Future<void> loadPoemsByBookId(dynamic bookId) async {
    try {
      debugPrint('🔄 Loading poems for book: $bookId');
      debugPrint('📥 Initial poems count: ${poems.length}');
      
      isLoading.value = true;
      error.value = '';
      poems.clear(); // Clear existing poems

      final int actualBookId;
      if (bookId is int) {
        actualBookId = bookId;
      } else if (bookId is String) {
        actualBookId = int.tryParse(bookId) ?? 0;
      } else {
        actualBookId = 0;
      }

      if (actualBookId <= 0) {
        error.value = 'Invalid book ID';
        return;
      }

      final result = await _poemRepository.getPoemsByBookId(actualBookId);
      debugPrint('📦 Query returned ${result.length} poems');
      
      // Validate results
      if (result.isEmpty) {
        error.value = 'No poems found for this book';
        return;
      }

      // Verify all poems belong to this book
      if (result.any((poem) => poem.bookId != actualBookId)) {
        debugPrint('⚠️ Found poems with mismatched book_id!');
        error.value = 'Data integrity error';
        return;
      }

      poems.assignAll(result);
      debugPrint('✅ Successfully loaded ${result.length} poems');

    } catch (e) {
      debugPrint('❌ Error: $e');
      error.value = 'Failed to load poems';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllPoems() async {
    try {
      debugPrint('⏳ Loading all poems');
      isLoading.value = true;
      error.value = '';
      poems.clear(); // Clear existing poems
      
      final result = await _poemRepository.getAllPoems();
      
      if (result.isEmpty) {
        error.value = 'No poems found';
      } else {
        poems.assignAll(result);
        debugPrint('✅ Loaded ${result.length} total poems');
        
        // Debug info
        final uniqueBookIds = result.map((p) => p.bookId).toSet();
        debugPrint('📊 Poems from books: $uniqueBookIds');
        debugPrint('First poem: ${result.first.title}');
        debugPrint('Last poem: ${result.last.title}');
      }
    } catch (e) {
      debugPrint('❌ Error loading poems: $e');
      error.value = 'Failed to load poems';
    } finally {
      isLoading.value = false;
    }
  }

  void onPoemTap(Poem poem) {
    Get.toNamed('/poem-detail', arguments: poem);
  }

  void sharePoem(Poem poem) {
    Share.share('${poem.title}\n\n${poem.data}\n\nFrom Iqbal Literature App');
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
      _saveFontSize();
    }
  }

  void decreaseFontSize() {
    if (fontSize.value > minFontSize) {
      fontSize.value -= 2.0;
      _saveFontSize();
    }
  }
}
