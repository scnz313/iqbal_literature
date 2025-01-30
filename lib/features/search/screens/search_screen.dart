import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as app_search;
import '../../../data/models/book/book.dart';
import '../../../data/models/poem/poem.dart';

class SearchScreen extends GetView<app_search.SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search books and poems...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Obx(() => controller.isLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const SizedBox.shrink()),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        if (controller.searchResults.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: controller.searchResults.length,
          itemBuilder: (context, index) {
            final result = controller.searchResults[index];
            if (result is Book) {
              return _buildBookTile(result);
            } else if (result is Poem) {
              return _buildPoemTile(result);
            }
            return const SizedBox.shrink();
          },
        );
      }),
    );
  }

  Widget _buildBookTile(Book book) {
    return ListTile(
      leading: const Icon(Icons.book),
      title: Text(
        book.name,
        style: const TextStyle(
          fontFamily: 'JameelNooriNastaleeq',
          fontSize: 18,
        ),
        textDirection: TextDirection.rtl,
      ),
      subtitle: book.language != null ? Text(book.language!) : null,
      onTap: () => controller.onResultTap(book),
    );
  }

  Widget _buildPoemTile(Poem poem) {
    return ListTile(
      leading: const Icon(Icons.format_quote),
      title: Text(
        poem.title,
        style: const TextStyle(
          fontFamily: 'JameelNooriNastaleeq',
          fontSize: 18,
        ),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        poem.data.split('\n').first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'JameelNooriNastaleeq',
          fontSize: 14,
        ),
        textDirection: TextDirection.rtl,
      ),
      onTap: () => controller.onResultTap(poem),
    );
  }
}
