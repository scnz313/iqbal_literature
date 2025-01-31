import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as app_search;
import '../widgets/search_result_tile.dart';
import '../widgets/search_result.dart';

class SearchScreen extends GetView<app_search.SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search poems, books, and verses...',
                    prefixIcon: const BackButton(),
                    suffixIcon: Obx(() => controller.isLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.searchResults.isEmpty && 
                    controller.searchController.text.isNotEmpty && 
                    !controller.isLoading.value) {
                  return const Center(
                    child: Text('No results found'),
                  );
                }

                return ListView.builder(
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      result: controller.searchResults[index],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
