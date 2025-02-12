import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as app_search;
import '../widgets/search_result_tile.dart';
import '../widgets/search_result.dart';

class SearchScreen extends GetView<app_search.SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search bar and voice button
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar(context)),
                      // Voice button with Obx
                      Obx(() => IconButton(
                        icon: Icon(
                          controller.isListening.value ? Icons.mic : Icons.mic_none,
                        ),
                        onPressed: controller.startVoiceSearch,
                      )),
                    ],
                  ),
                  
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(() => Row(
                      children: [
                        _buildFilterChip('All', null),
                        _buildFilterChip('Books', SearchResultType.book),
                        _buildFilterChip('Poems', SearchResultType.poem),
                        _buildFilterChip('Verses', SearchResultType.line),
                      ],
                    )),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: Obx(() {
                final query = controller.searchQuery;
                final isLoading = controller.isLoading.value;
                final results = controller.searchResults;

                // Show recent searches when no search is active
                if (query.isEmpty) {
                  return _buildRecentSearches(context);
                }

                // Show loading or search results
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (results.isEmpty) {
                  return _buildEmptyState(context);
                }

                return _buildSearchResults(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchResultType? type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: controller.selectedFilter.value == type,
        onSelected: (_) => controller.setFilter(type),
        backgroundColor: Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    return Obx(() {
      final searches = controller.recentSearches;
      if (searches.isEmpty) {
        return const Center(child: Text('No recent searches'));
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 8),
              const Text('Recent Searches'),
              const Spacer(),
              TextButton(
                onPressed: controller.clearRecentSearches,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searches.map((search) => _buildSearchChip(search)).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildSearchChip(String search) {
    final isUrdu = search.contains(RegExp(r'[\u0600-\u06FF]'));
    return InkWell(
      onTap: () => controller.applyRecentSearch(search),
      child: Chip(
        label: Text(
          search,
          style: TextStyle(
            fontFamily: isUrdu ? 'JameelNooriNastaleeq' : null,
            fontSize: isUrdu ? 18 : 14,
          ),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => controller.removeRecentSearch(search),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return ListView(
      controller: controller.scrollController,
      children: [
        // Books section - only show if there are book results
        if (controller.bookResults.isNotEmpty)
          _buildResultSection('Books', controller.bookResults),
          
        // Poems section - only show if there are poem results
        if (controller.poemResults.isNotEmpty)
          _buildResultSection('Poems', controller.poemResults),
          
        // Verses section - only show if there are verse results
        if (controller.verseResults.isNotEmpty)
          _buildResultSection('Verses', controller.verseResults),

        // Show "No results found" if all sections are empty
        if (controller.filteredResults.isEmpty && !controller.isLoading.value)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No results found for this filter',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultSection(String title, List<SearchResult> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(Get.context!).textTheme.titleMedium,
          ),
        ),
        ...results.map((result) => SearchResultTile(result: result)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Search icon
          Icon(Icons.search, color: Theme.of(context).hintColor),
          const SizedBox(width: 12),
          // Search fields
          Expanded(
            child: Row(
              children: [
                // English search field
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search in English...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Vertical divider with padding
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: VerticalDivider(
                    color: Theme.of(context).dividerColor,
                    width: 32,
                  ),
                ),
                // Urdu search field
                Expanded(
                  child: TextField(
                    controller: controller.urduSearchController,
                    onChanged: controller.onSearchChanged,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'JameelNooriNastaleeq',
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'اردو میں تلاش...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontFamily: 'JameelNooriNastaleeq',
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Theme.of(context).hintColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or search in Urdu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
