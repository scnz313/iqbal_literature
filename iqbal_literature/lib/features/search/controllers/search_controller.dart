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
  final TextEditingController searchController = TextEditingController();
  final TextEditingController urduSearchController = TextEditingController();
  Timer? _debounceTimer;
  String _lastQuery = '';
  final isListening = false.obs;

  // Support for responsive UI
  final isUrduMode = false.obs;

  // Simplify the recent searches handling
  final recentSearches = <String>[].obs;
  final selectedFilter = Rx<SearchResultType?>(null);
  final showScrollToTop = false.obs;
  final ScrollController scrollController = ScrollController();

  // Use RxString for searchQuery to properly track changes
  final RxString _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  // Filtered results
  final Rx<List<SearchResult>> _filteredResults = Rx<List<SearchResult>>([]);
  List<SearchResult> get filteredResults => _filteredResults.value;

  // Specific result type getters
  List<SearchResult> get bookResults {
    if (selectedFilter.value == SearchResultType.book ||
        selectedFilter.value == null) {
      return searchResults
          .where((r) => r.type == SearchResultType.book)
          .toList();
    }
    return [];
  }

  List<SearchResult> get poemResults {
    if (selectedFilter.value == SearchResultType.poem ||
        selectedFilter.value == null) {
      return searchResults
          .where((r) => r.type == SearchResultType.poem)
          .toList();
    }
    return [];
  }

  List<SearchResult> get verseResults {
    if (selectedFilter.value == SearchResultType.line ||
        selectedFilter.value == null) {
      return searchResults
          .where((r) => r.type == SearchResultType.line)
          .toList();
    }
    return [];
  }

  SearchController(this._searchService);

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _precacheData();

    // Set up listeners
    searchController.addListener(_updateSearchQuery);
    urduSearchController.addListener(_updateSearchQuery);
    scrollController.addListener(_onScroll);

    // Initialize language mode based on device locale
    final locale = Get.locale;
    if (locale != null) {
      // If device locale is Urdu, start with Urdu mode
      isUrduMode.value = locale.languageCode == 'ur';
    }

    // Load any saved language preference
    SharedPreferences.getInstance().then((prefs) {
      isUrduMode.value = prefs.getBool('isUrduSearchMode') ?? isUrduMode.value;
    });

    // Set up worker to update filtered results when the filter changes
    ever(selectedFilter, (_) {
      searchResults.refresh();
      update();
    });

    // Set up worker to detect language changes
    ever(isUrduMode, (_) {
      update();
    });

    // Set up worker to track recent searches changes
    ever(recentSearches, (_) {
      update();
    });
  }

  void _updateSearchQuery() {
    final query = searchController.text.isEmpty
        ? urduSearchController.text
        : searchController.text;
    _searchQuery.value = query;

    // Auto-detect language based on input
    detectLanguage(query);
  }

  void detectLanguage(String text) {
    if (text.isEmpty) return;

    final isUrduText = _containsUrdu(text);
    if (isUrduText && !isUrduMode.value) {
      isUrduMode.value = true;
    } else if (!isUrduText && isUrduMode.value) {
      isUrduMode.value = false;
    }
  }

  bool _containsUrdu(String text) {
    return text.contains(RegExp(r'[\u0600-\u06FF]'));
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
    _searchQuery.value = '';
    update();
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // Auto-detect language
    final isUrduQuery = _containsUrdu(query);

    // Sync controllers based on language
    if (isUrduQuery) {
      if (searchController.text.isNotEmpty) {
        searchController.clear();
      }

      // Only update if different to avoid infinite loop
      if (urduSearchController.text != query) {
        urduSearchController.text = query;
      }

      isUrduMode.value = true;
    } else {
      if (urduSearchController.text.isNotEmpty) {
        urduSearchController.clear();
      }

      // Only update if different to avoid infinite loop
      if (searchController.text != query) {
        searchController.text = query;
      }

      isUrduMode.value = false;
    }

    if (query.isEmpty) {
      searchResults.clear();
      _lastQuery = '';
      return;
    }

    // Don't search if query is too short, unless it's Urdu
    if (query.length < 2 && !isUrduQuery) {
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

  // Search with loading indicator and error handling
  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      isLoading.value = true;
      await _saveRecentSearch(query.trim());

      final results = await _searchService.search(query, limit: 50);
      searchResults.assignAll(results);

      // Reset the filter when performing a new search
      selectedFilter.value = null;
    } catch (e) {
      debugPrint('Search error: $e');
      searchResults.clear();
      Get.snackbar(
        'Search Error',
        'Could not complete search. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 3),
      );
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
    debugPrint('Setting filter to: $type');
    // Toggle filter if it's the same type
    if (selectedFilter.value == type) {
      selectedFilter.value = null;
    } else {
      selectedFilter.value = type;
    }

    // Force refresh the UI
    searchResults.refresh();
    update();
  }

  Future<bool> startVoiceSearch() async {
    try {
      if (!_speechService.isAvailable) {
        Get.snackbar(
          'Not Available',
          'Speech recognition is not available right now',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      if (!isListening.value) {
        // Start listening
        isListening.value = true;
        update();

        Get.snackbar(
          'Listening...',
          'Speak now to search',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        final success = await _speechService.listen(
          onResult: (text) {
            if (text.isNotEmpty) {
              debugPrint('Speech recognized: $text');

              // Check if the text contains Urdu characters
              final isUrduText = _containsUrdu(text);

              // Clear both text fields first to avoid conflict
              searchController.clear();
              urduSearchController.clear();

              // Update the correct search controller based on text language
              if (isUrduText) {
                urduSearchController.text = text;
                isUrduMode.value = true;
              } else {
                searchController.text = text;
                isUrduMode.value = false;
              }

              // Trigger search
              performSearch(text);

              // Update UI immediately
              update();
            }

            // Stop listening
            isListening.value = false;
            update();
          },
        );

        if (!success) {
          isListening.value = false;
          update();

          Get.snackbar(
            'Voice Search Failed',
            'Could not start voice recognition',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
        return true;
      } else {
        // Stop listening
        isListening.value = false;
        await _speechService.stop();
        update();
        return true;
      }
    } catch (e) {
      isListening.value = false;
      update();
      debugPrint('Voice search error: $e');
      Get.snackbar(
        'Error',
        'An error occurred during voice search',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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

      // Remove if already exists (to reorder it to the top)
      searches.remove(trimmedQuery);

      // Add to the beginning
      searches.insert(0, trimmedQuery);

      // Limit to 5 items
      searches = searches.take(5).toList();

      // Update UI and persistent storage
      await _updateRecentSearchesList(searches);

      debugPrint('Saved recent search: $trimmedQuery');
    } catch (e) {
      debugPrint('Error saving recent search: $e');
    }
  }

  Future<void> _updateRecentSearchesList(List<String> searches) async {
    try {
      // Clear and reassign to trigger reactive updates
      recentSearches.clear();
      recentSearches.assignAll(searches);

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', searches);

      // Force UI update
      update();
    } catch (e) {
      debugPrint('Error updating recent searches: $e');
    }
  }

  Future<bool> removeRecentSearch(String query) async {
    try {
      final searches = List<String>.from(recentSearches);
      if (searches.remove(query)) {
        await _updateRecentSearchesList(searches);
        debugPrint('Removed recent search: $query');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing recent search: $e');
      return false;
    }
  }

  Future<bool> clearRecentSearches() async {
    try {
      // Clear the list
      recentSearches.clear();

      // Remove from persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');

      // Force UI update
      update();

      debugPrint('Recent searches cleared');
      return true;
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
      return false;
    }
  }

  // Apply a recent search
  void applyRecentSearch(String query) {
    // Clear both fields first
    searchController.clear();
    urduSearchController.clear();

    if (_containsUrdu(query)) {
      // Urdu text
      urduSearchController.text = query;
      isUrduMode.value = true;
    } else {
      // English text
      searchController.text = query;
      isUrduMode.value = false;
    }

    // Perform search with the query
    performSearch(query);

    // Force UI update
    update();
  }

  // Toggle between Urdu and English mode
  void toggleSearchLanguage() {
    // Toggle the mode
    isUrduMode.value = !isUrduMode.value;

    // Save the preference
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isUrduSearchMode', isUrduMode.value);
    });

    // Preserve search text when switching
    final currentText = searchQuery;
    if (currentText.isNotEmpty) {
      // Clear both fields first
      searchController.clear();
      urduSearchController.clear();

      if (isUrduMode.value) {
        // Switching to Urdu
        urduSearchController.text = currentText;
      } else {
        // Switching to English
        searchController.text = currentText;
      }
    }

    // Force UI update
    update();
  }
}
