import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../books/screens/books_screen.dart';
import '../../poems/screens/poems_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../data/models/book/book.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/poem_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/models/poem/poem.dart';

class HomeController extends GetxController {
  final BookRepository _bookRepository;
  final PoemRepository _poemRepository;
  final AnalyticsService _analyticsService;

  final RxBool isLoading = false.obs;
  final RxList<Book> books = <Book>[].obs;
  final RxList<Poem> poems = <Poem>[].obs;
  final RxString error = ''.obs;

  HomeController({
    required BookRepository bookRepository,
    required PoemRepository poemRepository,
    required AnalyticsService analyticsService,
  })  : _bookRepository = bookRepository,
        _poemRepository = poemRepository,
        _analyticsService = analyticsService;

  final currentIndex = 0.obs;

  final List<Widget> pages = [
    const BooksScreen(),
    const PoemsScreen(),
    const SearchScreen(),
    const SettingsScreen(),
  ];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      error.value = '';

      await Future.wait([
        _loadBooks(),
        _loadPoems(),
      ]);

      _analyticsService.logEvent(
        name: 'home_data_loaded',
        parameters: {
          'books_count': books.length,
          'poems_count': poems.length,
        },
      );
    } catch (e) {
      error.value = 'Failed to load data';
      debugPrint('Error loading home data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadBooks() async {
    try {
      final result = await _bookRepository.getAllBooks();
      books.value = result;
    } catch (e) {
      debugPrint('Error loading books: $e');
      rethrow;
    }
  }

  Future<void> _loadPoems() async {
    try {
      final result = await _poemRepository.getAllPoems();
      poems.value = result;
    } catch (e) {
      debugPrint('Error loading poems: $e');
      rethrow;
    }
  }

  Future<void> refreshData() async {
    await loadData();
  }

  void onBookTap(Book book) {
    _analyticsService.logEvent(
      name: 'book_view',
      parameters: {
        'book_id': book.id,
        'book_name': book.name,
      },
    );
    Get.toNamed('/books/${book.id}', arguments: book);
  }

  void changePage(int index) {
    currentIndex.value = index;
  }

  Future<void> loadBooks() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final allBooks = await _bookRepository.getAllBooks();
      books.assignAll(allBooks);
      
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
