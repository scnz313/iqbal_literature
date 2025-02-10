import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../books/controllers/book_controller.dart';
import '../poems/controllers/poem_controller.dart';
import '../books/widgets/book_tile.dart';
import '../poems/widgets/poem_card.dart';  // Changed from poem_tile to poem_card

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookController bookController = Get.find();
    final PoemController poemController = Get.find();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Favorites',
            style: TextStyle(fontFamily: 'JameelNooriNastaleeq'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Books'),
              Tab(text: 'Poems'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Books tab
            Obx(() {
              if (bookController.favoriteBooks.isEmpty) {
                return _buildEmptyState(context, 'No favorite books');
              }
              return ListView.builder(
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
                return _buildEmptyState(context, 'No favorite poems');
              }
              return ListView.builder(
                itemCount: poemController.poems.length,
                itemBuilder: (context, index) {
                  final poem = poemController.poems[index];
                  if (!poemController.isFavorite(poem)) {
                    return const SizedBox.shrink();
                  }
                  return PoemCard(  // Changed from PoemTile to PoemCard
                    title: poem.title,
                    poem: poem,
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
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
    );
  }
}