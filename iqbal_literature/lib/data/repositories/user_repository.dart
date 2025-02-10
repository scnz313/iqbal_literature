import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user/user.dart';
import '../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;
  
  static const String _userKey = 'current_user';
  static const String _preferencesKey = 'user_preferences';

  UserRepository(this._firestore, this._storageService);

  Future<User?> getCurrentUser() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userKey)
          .get();
      return doc.exists ? User.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> toggleFavoriteBook(int bookId) async {
    try {
      final userRef = _firestore.collection('users').doc(_userKey);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;
        
        final user = User.fromFirestore(doc);
        final favorites = List<int>.from(user.favoriteBooks);
        
        if (favorites.contains(bookId)) {
          favorites.remove(bookId);
        } else {
          favorites.add(bookId);
        }
        
        transaction.update(userRef, {'favorite_books': favorites});
      });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> saveUser(User user) async {
    try {
      await _storageService.write(_userKey, user.toJson());
    } catch (e) {
      debugPrint('Failed to save user: $e');
    }
  }

  Future<void> toggleFavoritePoem(int poemId) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return;

      final favorites = List<int>.from(user.favoritePoems);
      if (favorites.contains(poemId)) {
        favorites.remove(poemId);
      } else {
        favorites.add(poemId);
      }

      final updatedUser = user.copyWith(favoritePoems: favorites.map((e) => e.toString()).toList());
      await saveUser(updatedUser);
    } catch (e) {
      debugPrint('Failed to toggle favorite poem: $e');
    }
  }

  Future<void> clearUserData() async {
    try {
      await _storageService.delete(_userKey);
      await _storageService.delete(_preferencesKey);
    } catch (e) {
      debugPrint('Failed to clear user data: $e');
    }
  }
}
