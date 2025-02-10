import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iqbal Literature'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .orderBy('title')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data!.docs;

          return AnimatedList(
            initialItemCount: books.length,
            itemBuilder: (context, index, animation) {
              final book = books[index];
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOut)),
                ),
                child: BookCard(
                  book: book,
                  onTap: () => Get.to(() => PoemListPage(bookId: book.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final QueryDocumentSnapshot book;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(book['title'] ?? ''),
        subtitle: Text(book['author'] ?? ''),
        onTap: onTap,
      ),
    );
  }
}

class PoemListPage extends StatelessWidget {
  final String bookId;

  const PoemListPage({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poems'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('poems')
            .where('bookId', isEqualTo: bookId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final poems = snapshot.data!.docs;
          return ListView.builder(
            itemCount: poems.length,
            itemBuilder: (context, index) {
              final poem = poems[index];
              return ListTile(
                title: Text(poem['title'] ?? ''),
                onTap: () {
                  // Navigate to poem detail page
                },
              );
            },
          );
        },
      ),
    );
  }
}