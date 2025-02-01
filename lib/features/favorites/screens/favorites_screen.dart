import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../books/controllers/book_controller.dart';
import '../../poems/controllers/poem_controller.dart';
import '../../books/widgets/book_tile.dart';
import '../../poems/widgets/poem_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookController = Get.find<BookController>();
    final poemController = Get.find<PoemController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Books'),
              Tab(text: 'Poems'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            // Books tab
            Obx(() {
              if (bookController.favoriteBooks.isEmpty) {
                return _buildEmptyState('No favorite books');
              }
              return _buildResponsiveList(
                context,
                itemCount: bookController.favoriteBooks.length,
                itemBuilder: (context, index) {
                  final book = bookController.favoriteBooks[index];
                  return BookTile(book: book);
                },
              );
            }),
            // Poems tab
            Obx(() {
              if (poemController.favorites.isEmpty) {
                return _buildEmptyState('No favorite poems');
              }
              return _buildResponsiveList(
                context,
                itemCount: poemController.poems.length,
                itemBuilder: (context, index) {
                  final poem = poemController.poems[index];
                  if (!poemController.isFavorite(poem)) {
                    return const SizedBox.shrink();
                  }
                  return InkWell(
                    onTap: () => poemController.onPoemTap(poem),
                    child: PoemCard(
                      title: poem.title,
                      poem: poem,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveList(
    BuildContext context, {
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    if (MediaQuery.of(context).size.width > 900) {
      // For wide screens, show grid
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }
    
    // For narrow screens, show list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  Widget _buildEmptyState(String message) {
    return Builder(
      builder: (BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

