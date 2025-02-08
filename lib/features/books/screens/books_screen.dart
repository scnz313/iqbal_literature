import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../widgets/book_tile.dart';  // Updated import
import '../../../data/models/book/book.dart';  // Import the Book model

class BooksScreen extends GetView<BookController> {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'کتابیں',
          style: TextStyle(
            fontFamily: 'JameelNooriNastaleeq',
            fontSize: 24,
          ),
          textDirection: TextDirection.rtl,
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.books.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.books.length,
          itemBuilder: (context, index) {
            final book = controller.books[index];
            return BookTile(book: book);  // Remove GestureDetector since BookTile handles interactions
          },
        );
      }),
    );
  }
}