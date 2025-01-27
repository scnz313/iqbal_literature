import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as custom;
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../data/models/book/book.dart';
import '../../../data/models/poem/poem.dart';

class SearchScreen extends GetView<custom.SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          controller: controller.searchController,
          hintText: 'Search poems, books, or lines...',
          hintStyle: WidgetStateProperty.all(
            const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
          ),
          leading: const Icon(Icons.search),
          trailing: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.searchController.clear();
                controller.searchResults.clear();
              },
            ),
          ],
          onSubmitted: controller.performSearch,
          onChanged: controller.onSearchChanged,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget();
        }

        if (controller.error.value.isNotEmpty) {
          return CustomErrorWidget(
            message: controller.error.value,
            onRetry: () => controller.performSearch(
              controller.searchController.text,
            ),
          );
        }

        if (controller.searchResults.isEmpty) {
          if (controller.searchController.text.isEmpty) {
            return _buildInitialState(context);
          }
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.searchResults.length,
          itemBuilder: (context, index) {
            final result = controller.searchResults[index];
            return _buildSearchResultItem(context, result);
          },
        );
      }),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for books and poems',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter keywords to find what you\'re looking for',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, dynamic result) {
    if (result is Book) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            result.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: 'JameelNooriNastaleeq',
            ),
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text(result.language),
          leading: const Icon(Icons.book),
          onTap: () => controller.onResultTap(result),
        ),
      );
    } else if (result is Poem) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            result.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: 'JameelNooriNastaleeq',
            ),
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text(
            result.data,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'JameelNooriNastaleeq',
            ),
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: const Icon(Icons.article),
          onTap: () => controller.onResultTap(result),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
