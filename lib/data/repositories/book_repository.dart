import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import '../models/book/book.dart';
import '../../features/poems/models/poem.dart';

class BookRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'books';
  static const String _favoritesKey = 'favorite_books';
  List<Book> _cache = [];

  BookRepository(this._firestore);
  Future<List<Book>> getAllBooks() async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .orderBy('order_by')
          .get();
      
      _cache = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
      return _cache;
      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching all books: $e');
      return [];
    }
  }

  Future<List<Book>> getBooks({String? lastDocumentId, int limit = 20}) async {
    try {
      Query query = _firestore.collection('books').orderBy('order_by');
      
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('books')
            .doc(lastDocumentId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching books: $e');
      return [];
    }
  }

  Future<List<Poem>> getPoemsByBookId(String bookId) async {
    try {
      debugPrint('Getting poems for book: $bookId');
      
      final snapshot = await _firestore
          .collection('poems')
          .where('book_id', isEqualTo: int.parse(bookId))
          .orderBy('order_by')
          .get();

      debugPrint('Found ${snapshot.docs.length} poems');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = int.parse(doc.id);
        debugPrint('Processing poem data: $data');
        return Poem.fromMap(data);
      }).toList();
      
    } catch (e, stack) {
      debugPrint('Error fetching poems for book $bookId: $e');
      debugPrint('Stack trace: $stack');
      return [];
    }
  }

  Future<List<Book>> searchBooks(String query, {int? limit}) async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(limit ?? 20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = int.parse(doc.id);
        return Book.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error searching books: $e');
      return [];
    }
  }

  Future<List<int>> getFavoriteBookIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey);
      if (favorites == null) return [];
      return favorites.map((id) => int.parse(id)).toList();
    } catch (e) {
      debugPrint('Error getting favorite books: $e');
      return [];
    }
  }

  Future<void> addFavorite(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      if (!favorites.contains(bookId.toString())) {
        favorites.add(bookId.toString());
        await prefs.setStringList(_favoritesKey, favorites);
      }
    } catch (e) {
      debugPrint('Error adding favorite: $e');
    }
  }

  Future<void> removeFavorite(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      favorites.remove(bookId.toString());
      await prefs.setStringList(_favoritesKey, favorites);
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  Future<bool> isFavorite(int bookId) async {
    final favorites = await getFavoriteBookIds();
    return favorites.contains(bookId);
  }

  Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }

  Book? getBookById(int id) {
    try {
      return _cache.firstWhereOrNull((book) => book.id == id);
    } catch (e) {
      debugPrint('Error getting book by id: $e');
      return null;
    }
  }
}