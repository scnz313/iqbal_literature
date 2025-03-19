import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/search_result.dart';
import '../../../data/services/search_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/speech_service_factory.dart';
import '../../../services/speech_service_stub.dart';

class SearchController extends GetxController {
  final SearchService _searchService;
  final SpeechService _speechService =
      SpeechServiceFactory.createSpeechService();
  final searchResults = <SearchResult>[].obs;
  final isLoading = false.obs;
  final searchController = TextEditingController();
  final urduSearchController = TextEditingController();
  Timer? _debounceTimer;
  String _lastQuery = '';
  final isListening = false.obs;

  // Simplify the recent searches handling
  final recentSearches = <String>[].obs;
  final selectedFilter = Rx<SearchResultType?>(null);
  final showScrollToTop = false.obs;
  final scrollController = ScrollController();
  bool get showRecentSearches {
    debugPrint('Recent searches length: ${recentSearches.length}');
    return recentSearches.isNotEmpty;
  }

  String get searchQuery => searchController.text.isEmpty
      ? urduSearchController.text
      : searchController.text;

  // Update the getter to filter results based on selected type
  List<SearchResult> get filteredResults {
    if (selectedFilter.value == null) {
      return searchResults;
    }
    return searchResults
        .where((result) => result.type == selectedFilter.value)
        .toList();
  }

  // Update getters to use selectedFilter
  List<SearchResult> get bookResults => selectedFilter.value == null ||
          selectedFilter.value == SearchResultType.book
      ? searchResults.where((r) => r.type == SearchResultType.book).toList()
      : [];

  List<SearchResult> get poemResults => selectedFilter.value == null ||
          selectedFilter.value == SearchResultType.poem
      ? searchResults.where((r) => r.type == SearchResultType.poem).toList()
      : [];

  List<SearchResult> get verseResults => selectedFilter.value == null ||
          selectedFilter.value == SearchResultType.line
      ? searchResults.where((r) => r.type == SearchResultType.line).toList()
      : [];

  // Minimum query length for search
  static const int _minQueryLength = 2;

  SearchController(this._searchService);

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _precacheData();
    scrollController.addListener(_onScroll);
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
    scrollController.dispose();
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
      // Remove the await since we're in a void callback
      performSearch(query); // Remove await
    });
  }

  // Update performSearch to maintain all results
  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      isLoading.value = true;
      await _saveRecentSearch(query.trim());

      final results =
          await _searchService.search(query, limit: 50); // Increased limit
      searchResults.assignAll(results);
    } catch (e) {
      debugPrint('Search error: $e');
      searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _onScroll() {
    showScrollToTop.value = scrollController.offset > 500;
  }

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void setFilter(SearchResultType? type) {
    selectedFilter.value = type;
    // No need to perform new search, just update the UI with filtered results
    searchResults.refresh();
  }

  Future<void> startVoiceSearch() async {
    try {
      if (!_speechService.isAvailable) {
        Get.snackbar(
          'Not Available',
          'Speech recognition is not available right now',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (!isListening.value) {
        // Start listening
        isListening.value = true;
        final success = await _speechService.listen(
          onResult: (text) {
            // Check if the text contains Urdu characters
            final isUrduText = text.contains(RegExp(r'[\u0600-\u06FF]'));

            // Update the correct search controller based on text language
            if (isUrduText) {
              urduSearchController.text = text;
              searchController.clear();
            } else {
              searchController.text = text;
              urduSearchController.clear();
            }

            // Trigger search
            performSearch(text);
          },
        );

        if (!success) {
          isListening.value = false;
          Get.snackbar(
            'Voice Search Failed',
            'Could not start voice recognition',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Listening...',
            'Speak now to search',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Stop listening
        isListening.value = false;
        await _speechService.stop();
      }
    } catch (e) {
      isListening.value = false;
      debugPrint('Voice search error: $e');
      Get.snackbar(
        'Error',
        'An error occurred during voice search',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      recentSearches.assignAll(searches);
      debugPrint('Loaded ${searches.length} recent searches');
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final trimmedQuery = query.trim();
      var searches = List<String>.from(recentSearches);
      searches.remove(trimmedQuery);
      searches.insert(0, trimmedQuery);
      searches = searches.take(5).toList();

      recentSearches.value = searches;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', searches);
      debugPrint('Saved recent search: $trimmedQuery');
    } catch (e) {
      debugPrint('Error saving recent search: $e');
    }
  }

  void removeRecentSearch(String query) async {
    try {
      recentSearches.remove(query);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', recentSearches);
      debugPrint('Removed recent search: $query');
    } catch (e) {
      debugPrint('Error removing recent search: $e');
    }
  }

  void clearRecentSearches() async {
    try {
      recentSearches.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      debugPrint('Recent searches cleared');
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  // Add method to apply recent search
  void applyRecentSearch(String query) {
    if (query.contains(RegExp(r'[\u0600-\u06FF]'))) {
      // Urdu text
      urduSearchController.text = query;
      searchController.clear();
    } else {
      // English text
      searchController.text = query;
      urduSearchController.clear();
    }
    performSearch(query);
  }

  // New method to immediately load searches
  void _loadRecentSearchesNow() {
    SharedPreferences.getInstance().then((prefs) {
      final searches = prefs.getStringList('recent_searches') ?? [];
      debugPrint('Loading recent searches: $searches');
      recentSearches.value = searches;
      recentSearches.refresh();
    });
  }
}
