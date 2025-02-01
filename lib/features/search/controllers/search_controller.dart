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
  final urduSearchController = TextEditingController();
  Timer? _debounceTimer;
  String _lastQuery = '';

  // Minimum query length for search
  static const int _minQueryLength = 2;

  SearchController(this._searchService);

  @override
  void onInit() {
    super.onInit();
    // Pre-cache data when controller is initialized
    _precacheData();
  }

  Future<void> _precacheData() async {
    try {
      // Trigger initial search to cache data
      await _searchService.search('', limit: 1);
    } catch (e) {
      debugPrint('Precache error: $e');
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    urduSearchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }

  void clearSearch() {
    searchController.clear();
    urduSearchController.clear();
    searchResults.clear();
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    // Sync both text fields
    final isUrduQuery = query.contains(RegExp(r'[\u0600-\u06FF]'));
    if (isUrduQuery) {
      if (searchController.text.isNotEmpty) searchController.clear();
    } else {
      if (urduSearchController.text.isNotEmpty) urduSearchController.clear();
    }
    
    if (query.isEmpty) {
      searchResults.clear();
      _lastQuery = '';
      return;
    }

    // Don't search if query is too short, unless it's Urdu
    if (query.length < _minQueryLength && !isUrduQuery) {
      return;
    }

    // Don't search if query hasn't changed
    if (query == _lastQuery) {
      return;
    }

    _lastQuery = query;
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
      searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
