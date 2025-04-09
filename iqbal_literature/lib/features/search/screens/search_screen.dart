import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      floatingActionButton: _buildScrollToTopButton(),
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced search header with animated container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search bar and voice button in an animated container
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchBar(context),
                      ),
                      // Voice button with animation
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GetBuilder<app_search.SearchController>(
                          builder: (ctrl) => IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                ctrl.isListening.value
                                    ? Icons.mic
                                    : Icons.mic_none,
                                key: ValueKey(ctrl.isListening.value),
                                color: ctrl.isListening.value
                                    ? theme.colorScheme.primary
                                    : theme.iconTheme.color,
                              ),
                            ),
                            onPressed: () async {
                              // Use haptic feedback
                              HapticFeedback.mediumImpact();
                              await ctrl.startVoiceSearch();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Enhanced filter chips with proper reactive handling
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: GetBuilder<app_search.SearchController>(
                      builder: (ctrl) => Row(
                        children: [
                          _buildFilterChip(context, 'All', null),
                          _buildFilterChip(
                              context, 'Books', SearchResultType.book),
                          _buildFilterChip(
                              context, 'Poems', SearchResultType.poem),
                          _buildFilterChip(
                              context, 'Verses', SearchResultType.line),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area with content based on search state
            Expanded(
              child: GetBuilder<app_search.SearchController>(
                builder: (ctrl) => _buildContentArea(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(BuildContext context) {
    final query = controller.searchQuery;
    final isLoading = controller.isLoading.value;
    final hasResults = controller.searchResults.isNotEmpty;

    if (query.isEmpty) {
      return _buildRecentSearches(context);
    } else if (isLoading) {
      return _buildLoadingState(context);
    } else if (!hasResults) {
      return _buildEmptyState(context);
    } else {
      return _buildSearchResults(context);
    }
  }

  Widget _buildFilterChip(
      BuildContext context, String label, SearchResultType? type) {
    final theme = Theme.of(context);
    final isSelected = controller.selectedFilter.value == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => controller.setFilter(type),
        backgroundColor: Colors.transparent,
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 0 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    final theme = Theme.of(context);
    final recentSearches = controller.recentSearches;

    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.hintColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent searches',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your search history will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    // Use haptic feedback
                    HapticFeedback.lightImpact();

                    final success = await controller.clearRecentSearches();
                    if (success) {
                      Get.snackbar(
                        'Cleared',
                        'Recent searches have been cleared',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: recentSearches
                  .map((search) => _buildSearchChip(context, search))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchChip(BuildContext context, String search) {
    final theme = Theme.of(context);
    final isUrdu = search.contains(RegExp(r'[\u0600-\u06FF]'));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Use haptic feedback
          HapticFeedback.selectionClick();
          controller.applyRecentSearch(search);
        },
        borderRadius: BorderRadius.circular(20),
        child: Chip(
          label: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            child: Text(
              search,
              style: TextStyle(
                fontFamily: isUrdu ? 'JameelNooriNastaleeq' : null,
                fontSize: isUrdu ? 18 : 14,
                color: theme.textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          backgroundColor: theme.cardColor,
          side: BorderSide(color: theme.dividerColor),
          deleteIcon: Icon(
            Icons.close,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          onDeleted: () async {
            // Use haptic feedback
            HapticFeedback.lightImpact();

            final success = await controller.removeRecentSearch(search);
            if (success) {
              Get.snackbar(
                'Removed',
                'Search "$search" has been removed',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            }
          },
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFilter = controller.selectedFilter.value;
    final screenWidth = MediaQuery.of(context).size.width;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          controller.showScrollToTop.value = notification.metrics.pixels > 500;
        }
        return false;
      },
      child: ListView(
        controller: controller.scrollController,
        padding: const EdgeInsets.only(bottom: 80), // Add padding for FAB
        children: [
          // Books section - only show if applicable
          if (selectedFilter == null || selectedFilter == SearchResultType.book)
            if (controller.bookResults.isNotEmpty)
              _buildResultSection(context, 'Books', controller.bookResults,
                  Icons.book_outlined),

          // Poems section - only show if applicable
          if (selectedFilter == null || selectedFilter == SearchResultType.poem)
            if (controller.poemResults.isNotEmpty)
              _buildResultSection(context, 'Poems', controller.poemResults,
                  Icons.article_outlined),

          // Verses section - only show if applicable
          if (selectedFilter == null || selectedFilter == SearchResultType.line)
            if (controller.verseResults.isNotEmpty)
              _buildResultSection(context, 'Verses', controller.verseResults,
                  Icons.format_quote_outlined),

          // Show message when filter is applied but no results match that filter
          if ((selectedFilter != null) &&
              ((selectedFilter == SearchResultType.book &&
                      controller.bookResults.isEmpty) ||
                  (selectedFilter == SearchResultType.poem &&
                      controller.poemResults.isEmpty) ||
                  (selectedFilter == SearchResultType.line &&
                      controller.verseResults.isEmpty)))
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 48,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results match this filter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Use haptic feedback
                        HapticFeedback.selectionClick();
                        controller.setFilter(null);
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filter'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultSection(BuildContext context, String title,
      List<SearchResult> results, IconData icon) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with icon, title and count
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${results.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results list with limited animations for better performance
        ...results.take(30).map((result) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: screenWidth - 32,
                child: SearchResultTile(result: result),
              ),
            )),

        const SizedBox(height: 8), // Add some space after the section
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 720;
    debugPrint('Screen Width: $screenWidth, isMobile: $isMobile');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              const SizedBox(width: 16),
              // Search icon with animated color
              GetBuilder<app_search.SearchController>(
                builder: (ctrl) => Icon(
                  Icons.search,
                  color: ctrl.searchQuery.isEmpty
                      ? theme.hintColor
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Search fields
              Expanded(
                child: isMobile
                    ? _buildMobileSearchFields(context)
                    : _buildDesktopSearchFields(context),
              ),
              // Clear button that appears when there is text
              GetBuilder<app_search.SearchController>(
                builder: (ctrl) => ctrl.searchQuery.isEmpty
                    ? const SizedBox(width: 16)
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // Use haptic feedback
                          HapticFeedback.lightImpact();
                          ctrl.clearSearch();
                        },
                        color: theme.hintColor,
                        iconSize: 18,
                        splashRadius: 20,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSearchFields(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<app_search.SearchController>(
      builder: (ctrl) {
        final isUrduMode = ctrl.isUrduMode.value;

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: isUrduMode
                    ? ctrl.urduSearchController
                    : ctrl.searchController,
                onChanged: ctrl.onSearchChanged,
                textDirection:
                    isUrduMode ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isUrduMode ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: isUrduMode ? 18 : 16,
                  fontFamily: isUrduMode ? 'JameelNooriNastaleeq' : null,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText:
                      isUrduMode ? 'اردو میں تلاش...' : 'Search in English...',
                  hintStyle: TextStyle(
                    color: theme.hintColor,
                    fontFamily: isUrduMode ? 'JameelNooriNastaleeq' : null,
                  ),
                  hintTextDirection:
                      isUrduMode ? TextDirection.rtl : TextDirection.ltr,
                  border: InputBorder.none,
                ),
              ),
            ),
            // Language toggle button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Use haptic feedback
                  HapticFeedback.mediumImpact();
                  ctrl.toggleSearchLanguage();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUrduMode ? Icons.language : Icons.translate,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUrduMode ? 'English' : 'اردو',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontFamily:
                              !isUrduMode ? 'JameelNooriNastaleeq' : null,
                          fontSize: !isUrduMode ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopSearchFields(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is too small, use the mobile layout instead
        if (constraints.maxWidth < 400) {
          return _buildMobileSearchFields(context);
        }

        return Row(
          children: [
            // English search field
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Search in English...',
                  hintStyle: TextStyle(color: theme.hintColor),
                  border: InputBorder.none,
                ),
              ),
            ),
            // Vertical divider with padding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: VerticalDivider(
                color: theme.dividerColor,
                width: 32,
              ),
            ),
            // Urdu search field
            Expanded(
              child: TextField(
                controller: controller.urduSearchController,
                onChanged: controller.onSearchChanged,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'JameelNooriNastaleeq',
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'اردو میں تلاش...',
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: TextStyle(
                    color: theme.hintColor,
                    fontFamily: 'JameelNooriNastaleeq',
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isUrduMode = controller.isUrduMode.value;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: theme.colorScheme.error.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No results found',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  'Try different keywords or switch language',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Use haptic feedback
                      HapticFeedback.mediumImpact();
                      controller.clearSearch();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Use haptic feedback
                      HapticFeedback.mediumImpact();
                      controller.toggleSearchLanguage();
                    },
                    icon: Icon(isUrduMode ? Icons.language : Icons.translate),
                    label: Text(isUrduMode ? 'Try English' : 'Try Urdu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Searching...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: GetBuilder<app_search.SearchController>(
              builder: (ctrl) => Text(
                'Looking for "${ctrl.searchQuery}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToTopButton() {
    return GetBuilder<app_search.SearchController>(
      builder: (ctrl) {
        final visible = ctrl.showScrollToTop.value;

        return AnimatedScale(
          scale: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton(
              onPressed: () {
                // Use haptic feedback
                HapticFeedback.selectionClick();
                ctrl.scrollToTop();
              },
              mini: true,
              child: const Icon(Icons.arrow_upward),
            ),
          ),
        );
      },
    );
  }
}
