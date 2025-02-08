import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../../../data/models/book/book.dart';

class BookTile extends StatelessWidget {
  final Book book;

  const BookTile({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookController>();
    
    return InkWell(
      onTap: () => controller.onBookTap(book),
      onLongPress: () => _showBookOptions(context, controller),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.book,
              color: Theme.of(context).primaryColor,
            ),
          ),
          title: Text(
            book.name,
            style: const TextStyle(
              fontFamily: 'JameelNooriNastaleeq',
              fontSize: 20,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text(
            book.language,
            style: const TextStyle(
              fontFamily: 'JameelNooriNastaleeq',
              fontSize: 16,
            ),
            textDirection: TextDirection.rtl,
          ),
          trailing: Obx(() => IconButton(
            icon: Icon(
              controller.isFavorite(book) 
                  ? Icons.favorite 
                  : Icons.favorite_border,
              color: controller.isFavorite(book)
                  ? Colors.red
                  : null,
            ),
            onPressed: () => controller.toggleFavorite(book),
          )),
        ),
      ),
    );
  }

  void _showBookOptions(BuildContext context, BookController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeline option
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Historical Timeline'),
            onTap: () {
              Navigator.pop(context);
              _showTimeline(context);
            },
          ),
          // Favorites option
          ListTile(
            leading: Icon(
              controller.isFavorite(book) 
                  ? Icons.favorite 
                  : Icons.favorite_border,
              color: controller.isFavorite(book) ? Colors.red : null,
            ),
            title: Text(
              controller.isFavorite(book)
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
            ),
            onTap: () {
              controller.toggleFavorite(book);
              Navigator.pop(context);
            },
          ),
          // Share option
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              controller.shareBook(book);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showTimeline(BuildContext context) {
    Get.toNamed('/timeline', arguments: {
      'book_id': book.id,
      'book_name': book.name,
      'time_period': book.timePeriod,
    });
  }
}
