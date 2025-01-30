import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/poem_repository.dart';
import '../../../data/models/book/book.dart';
import '../../../data/models/poem/poem.dart';

class SearchController extends GetxController {
  final BookRepository _bookRepository;
  final PoemRepository _poemRepository;

  SearchController(this._bookRepository, this._poemRepository);

  final searchResults = <dynamic>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    // Clear results if query is empty
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    // Debounce search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      performSearch(query);
    });
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';
      
      debugPrint('🔍 Starting search for: $query');

      // Perform searches in parallel
      final results = await Future.wait([
        _searchBooks(query),
        _searchPoems(query),
      ]);

      final books = results[0];
      final poems = results[1];

      // Sort and combine results
      final allResults = [...books, ...poems];
      
      debugPrint('📊 Search Results:');
      debugPrint('Books found: ${books.length}');
      debugPrint('Poems found: ${poems.length}');
      debugPrint('Total results: ${allResults.length}');

      searchResults.assignAll(allResults);

    } catch (e) {
      error.value = 'Search failed: $e';
      debugPrint('❌ Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Book>> _searchBooks(String query) async {
    try {
      final results = await _bookRepository.searchBooks(query);
      debugPrint('Found ${results.length} books');
      return results;
    } catch (e) {
      debugPrint('Error searching books: $e');
      return [];
    }
  }

  Future<List<Poem>> _searchPoems(String query) async {
    try {
      final results = await _poemRepository.searchPoems(query);
      debugPrint('Found ${results.length} poems');
      return results;
    } catch (e) {
      debugPrint('Error searching poems: $e');
      return [];
    }
  }

  void onResultTap(dynamic result) {
    if (result is Book) {
      Get.toNamed('/poems', arguments: {
        'book_id': result.id,
        'book_name': result.name,
      });
    } else if (result is Poem) {
      Get.toNamed('/poem-detail', arguments: result);
    }
  }
}
