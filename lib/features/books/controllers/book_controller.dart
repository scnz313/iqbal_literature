import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/book/book.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/services/analytics_service.dart';

class BookController extends GetxController {
  final BookRepository _bookRepository;
  final AnalyticsService _analyticsService;

  final RxList<Book> books = <Book>[].obs;
  final RxList<Book> favoriteBooks = <Book>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  BookController(this._bookRepository, this._analyticsService);

  @override
  void onInit() {
    super.onInit();
    loadBooks();
    loadFavorites();
  }

  Future<void> loadBooks() async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _bookRepository.getBooks();
      books.assignAll(result);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFavorites() async {
    try {
      final favoriteIds = await _bookRepository.getFavoriteBookIds();
      favoriteBooks.assignAll(
        books.where((book) => favoriteIds.contains(book.id))
      );
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(Book book) async {
    try {
      if (isFavorite(book)) {
        await _bookRepository.removeFavorite(book.id);
        favoriteBooks.remove(book);
      } else {
        await _bookRepository.addFavorite(book.id);
        favoriteBooks.add(book);
      }
      _analyticsService.logEvent(
        name: 'toggle_favorite_book',
        parameters: {
          'book_id': book.id,
          'book_name': book.name,
          'is_favorite': isFavorite(book),
        },
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  bool isFavorite(Book book) => favoriteBooks.contains(book);

  void shareBook(Book book) {
    Share.share(
      'Check out this book: ${book.name} from Iqbal Literature App',
      subject: book.name,
    );
  }

  void onBookTap(Book book) {
    _analyticsService.logBookView(book.id, book.name);
    Get.toNamed(
      '/poems',
      arguments: {
        'book_id': book.id,
        'book_name': book.name,
      },
    );
  }
}