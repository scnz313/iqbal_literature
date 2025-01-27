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

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
    final args = Get.arguments;
    debugPrint('📥 Received arguments: $args');
    
    if (args != null && args is Map<String, dynamic>) {
      final bookId = args['book_id'];
      final bookName = args['book_name'];
      
      debugPrint('🔍 Loading poems for book: $bookId ($bookName)');
      currentBookName.value = bookName ?? '';
      
      if (bookId != null) {
        // Ensure bookId is an integer
        final actualBookId = bookId is int ? bookId : int.tryParse(bookId.toString()) ?? 0;
        if (actualBookId > 0) {
          loadPoemsByBookId(actualBookId);
        } else {
          error.value = 'Invalid book ID';
          debugPrint('❌ Invalid book ID: $bookId');
        }
      }
    } else {
      debugPrint('❌ No valid arguments received');
      error.value = 'No book selected';
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

  bool isFavorite(Poem poem) => favorites.contains(poem.id);

  void toggleFavorite(Poem poem) {
    if (isFavorite(poem)) {
      favorites.remove(poem.id);
    } else {
      favorites.add(poem.id);
    }
    _saveFavorites();
  }

  Future<void> loadPoemsByBookId(int bookId) async {
    try {
      debugPrint('⏳ Loading poems for book_id: $bookId');
      isLoading.value = true;
      error.value = '';
      
      final result = await _poemRepository.getPoemsByBookId(bookId);
      
      if (result.isEmpty) {
        debugPrint('⚠️ No poems found for book_id: $bookId');
        error.value = 'No poems found for this book';
      } else {
        debugPrint('✅ Found ${result.length} poems');
        // Log the first poem for debugging
        if (result.isNotEmpty) {
          debugPrint('First poem: ${result.first.toMap()}');
        }
        poems.assignAll(result);
      }
    } catch (e, stack) {
      debugPrint('❌ Error: $e');
      debugPrint('Stack trace: $stack');
      error.value = 'Failed to load poems: ${e.toString()}';
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
}
