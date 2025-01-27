import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../books/controllers/book_controller.dart';
import '../../books/widgets/book_tile.dart';

class FavoritesScreen extends GetView<BookController> {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontFamily: 'JameelNooriNastaleeq'),
        ),
      ),
      body: Obx(() {
        if (controller.favoriteBooks.isEmpty) {
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
                const Text(
                  'No favorite books yet',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.favoriteBooks.length,
          itemBuilder: (context, index) {
            final book = controller.favoriteBooks[index];
            return BookTile(book: book);
          },
        );
      }),
    );
  }
}

