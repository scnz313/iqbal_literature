import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poem/poem.dart';
import '../models/line/line.dart';

class PoemRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'poems';

  PoemRepository(this._firestore);

  Future<List<Poem>> getAllPoems({String? lastDocumentId, int? limit}) async {
    try {
      debugPrint('Fetching all poems, lastDocId: $lastDocumentId, limit: $limit');

      Query<Map<String, dynamic>> query = _firestore
          .collection(_collection)
          .orderBy('_id')  // Changed to _id to match existing index
          .orderBy('__name__')  // Added to match index
          .limit(limit ?? 20);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(_collection)
            .doc(lastDocumentId)
            .get();
            
        debugPrint('Last document exists: ${lastDoc.exists}');
        
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} poems');

      final poems = snapshot.docs.map((doc) {
        try {
          final poem = Poem.fromFirestore(doc);
          debugPrint('Parsed poem: ${poem.id} - ${poem.title}');
          return poem;
        } catch (e) {
          debugPrint('Error parsing poem ${doc.id}: $e');
          return null;
        }
      }).whereType<Poem>().toList();

      debugPrint('Successfully parsed ${poems.length} poems');
      return poems;

    } catch (e) {
      debugPrint('Error fetching poems: $e');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      return [];
    }
  }

  Future<Poem?> getPoemById(String id) async {
    try {
      final doc = await _firestore.collection('poems').doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return Poem.fromMap(data);
    } catch (e) {
      debugPrint('Failed to fetch poem: $e');
      return null;
    }
  }

  Future<List<Poem>> getPoemsByBookId(int bookId) async {
    try {
      debugPrint('🔎 Starting query for book_id: $bookId');

      // Debug the exact query parameters
      debugPrint('Query parameters - book_id: $bookId (${bookId.runtimeType})');

      final querySnapshot = await _firestore
          .collection('poems')
          .where('book_id', isEqualTo: bookId)
          .get();

      // Debug the raw results
      debugPrint('📚 Raw query results:');
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        debugPrint('Document ${doc.id}: $data');
        debugPrint('book_id from doc: ${data['book_id']} (${data['book_id'].runtimeType})');
      }

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ No poems found for book_id: $bookId');
        return [];
      }

      final poems = querySnapshot.docs
          .map((doc) => Poem.fromFirestore(doc))
          .toList();

      debugPrint('✅ Successfully mapped ${poems.length} poems for book_id: $bookId');
      return poems;

    } catch (e, stack) {
      debugPrint('❌ Repository error: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  Future<List<Line>> getLinesByPoemId(int poemId) async {
    try {
      debugPrint('Fetching lines for poem: $poemId');
      
      final snapshot = await _firestore
          .collection('lines')
          .where('poem_id', isEqualTo: poemId)
          .orderBy('order_by')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No lines found for poem: $poemId');
        return [];
      }

      return snapshot.docs
          .map((doc) => Line.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching lines: $e');
      return [];
    }
  }

  Future<List<Poem>> searchPoems(String query, {int? limit}) async {
    try {
      debugPrint('🔍 Searching poems with query: $query');
      
      // Using index: data (Ascending), _id (Ascending), __name__ (Ascending)
      final snapshot = await _firestore
          .collection('poems')
          .where('data', isGreaterThanOrEqualTo: query)
          .where('data', isLessThan: '$query\uf8ff')
          .orderBy('data')
          .orderBy('_id')
          .orderBy('__name__')
          .limit(limit ?? 20)
          .get();

      debugPrint('📚 Found ${snapshot.docs.length} matching poems');

      final poems = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          debugPrint('Processing doc ${doc.id}: ${data['title']}');
          return Poem.fromMap(data);
        } catch (e) {
          debugPrint('❌ Error parsing poem ${doc.id}: $e');
          return null;
        }
      }).whereType<Poem>().toList();

      debugPrint('✅ Successfully parsed ${poems.length} poems');
      return poems;

    } catch (e) {
      debugPrint('❌ Search error: $e');
      return [];
    }
  }
}
