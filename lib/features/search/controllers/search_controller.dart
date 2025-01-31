import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/search_result.dart';
import '../../../data/services/search_service.dart';
import 'dart:async';

class SearchController extends GetxController {
  final SearchService _searchService;
  final searchResults = <SearchResult>[].obs;
  final isLoading = false.obs;
  final searchController = TextEditingController();
  Timer? _debounceTimer;

  SearchController(this._searchService);

  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      performSearch(query);
    });
  }

  Future<void> performSearch(String query) async {
    try {
      isLoading.value = true;
      final results = await _searchService.search(query, limit: 20);
      searchResults.assignAll(results);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
