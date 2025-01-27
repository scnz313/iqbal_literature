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
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      performSearch(query);
    });
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      final books = await _searchBooks(query);
      final poems = await _searchPoems(query);
      
      searchResults.assignAll([...books, ...poems]);
    } catch (e) {
      error.value = 'Search failed: $e';
      debugPrint('Search error: $e');
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
