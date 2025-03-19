import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/book/book.dart';
import '../../features/poems/models/poem.dart';

class BookRepository {
  final FirebaseFirestore _firestore;
  static const String _favoritesBoxName = 'favorite_books';
  static const String _booksBoxName = 'books_cache';
  static const String _allBooksKey = 'all_books';
  static const Duration _cacheDuration = Duration(days: 30);

  List<Book> _cache = [];
  late Box _favoritesBox;
  late Box _cacheBox;
  bool _isInitialized = false;

  BookRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _favoritesBox = await Hive.openBox(_favoritesBoxName);
    _cacheBox = await Hive.openBox(_booksBoxName);
    _isInitialized = true;

    // Try to load cache on initialization
    final cachedData = _cacheBox.get(_allBooksKey);
    if (cachedData != null) {
      final cacheTime = _cacheBox.get('${_allBooksKey}_time');
      if (cacheTime != null) {
        final cachedAt = DateTime.parse(cacheTime);
        if (DateTime.now().difference(cachedAt) < _cacheDuration) {
          try {
            final List<dynamic> data = cachedData;
            _cache = data
                .map((item) {
                  try {
                    final map = Map<String, dynamic>.from(item);
                    // Make sure id is not null
                    if (map['_id'] == null) {
                      debugPrint('⚠️ Found null id in cached book, skipping');
                      return null;
                    }
                    return Book.fromMap(map);
                  } catch (e) {
                    debugPrint('⚠️ Error parsing cached book: $e');
                    return null;
                  }
                })
                .whereType<Book>() // Filter out nulls
                .toList();
            debugPrint(
                '📦 Loaded ${_cache.length} books from persistent cache on init');
          } catch (e) {
            debugPrint('❌ Error loading cached books on init: $e');
            _cache = []; // Reset cache on error
          }
        }
      }
    }
  }

  Future<List<Book>> getAllBooks() async {
    await _initialize();

    // If cache is already populated, return it
    if (_cache.isNotEmpty) {
      debugPrint('📦 Using memory-cached books (${_cache.length} books)');
      return _cache;
    }

    try {
      debugPrint('Fetching all books from Firestore');
      QuerySnapshot snapshot = await _firestore.collection('books').get();

      _cache = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Book.fromMap(data);
      }).toList();

      // Sort by book ID
      _cache.sort((a, b) => a.id.compareTo(b.id));

      // Persist the cache
      try {
        final serializableData = _cache.map((book) => book.toMap()).toList();
        await _cacheBox.put(_allBooksKey, serializableData);
        await _cacheBox.put(
            '${_allBooksKey}_time', DateTime.now().toIso8601String());
        debugPrint('📦 Persisted ${_cache.length} books to cache');
      } catch (e) {
        debugPrint('❌ Error persisting books cache: $e');
      }

      return _cache;
    } catch (e) {
      debugPrint('Error fetching books: $e');
      return [];
    }
  }

  Future<List<Book>> getBooks() async {
    return getAllBooks();
  }

  Future<List<Poem>> getPoemsByBookId(String bookId) async {
    try {
      debugPrint('Fetching poems for book: $bookId');
      QuerySnapshot snapshot = await _firestore
          .collection('poems')
          .where('book_id', isEqualTo: int.parse(bookId))
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Poem.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching poems: $e');
      return [];
    }
  }

  Future<void> addFavorite(int bookId) async {
    await _initialize();
    Set<int> favorites = await getFavoriteBookIds();
    favorites.add(bookId);
    await _favoritesBox.put('favorites', favorites.toList());
  }

  Future<void> removeFavorite(int bookId) async {
    await _initialize();
    Set<int> favorites = await getFavoriteBookIds();
    favorites.remove(bookId);
    await _favoritesBox.put('favorites', favorites.toList());
  }

  Future<Set<int>> getFavoriteBookIds() async {
    await _initialize();
    final favorites = _favoritesBox.get('favorites', defaultValue: <int>[]);
    return Set<int>.from(favorites);
  }

  Future<void> clearCache() async {
    await _initialize();
    _cache = [];
    await _cacheBox.clear();
    debugPrint('🧹 Book cache cleared');
  }
}
