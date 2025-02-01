import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poem/poem.dart';
import '../models/line/line.dart';

class PoemRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'poems';

  PoemRepository(this._firestore);

  Future<List<Poem>> getPoemsByBookId(int bookId) async {
    try {
      debugPrint('\n==== FIRESTORE QUERY ====');
      debugPrint('📥 Book ID: $bookId (${bookId.runtimeType})');

      // Execute query with strict filtering
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(_collection)
          .where('book_id', isEqualTo: bookId)
          .get();

      debugPrint('📊 Raw query returned ${snapshot.docs.length} documents');

      final poems = <Poem>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final docBookId = data['book_id'];
          
          debugPrint('\nProcessing document:');
          debugPrint('- ID: ${doc.id}');
          debugPrint('- book_id: $docBookId (${docBookId.runtimeType})');
          debugPrint('- title: ${data['title']}');

          // Strict type and value checking
          if (docBookId == null) {
            debugPrint('❌ Skipping - null book_id');
            continue;
          }

          final int actualBookId;
          if (docBookId is int) {
            actualBookId = docBookId;
          } else if (docBookId is num) {
            actualBookId = docBookId.toInt();
          } else {
            debugPrint('❌ Skipping - invalid book_id type');
            continue;
          }

          if (actualBookId != bookId) {
            debugPrint('❌ Skipping - book_id mismatch');
            continue;
          }

          final poem = Poem.fromFirestore(doc);
          poems.add(poem);
          debugPrint('✅ Added poem to results');

        } catch (e) {
          debugPrint('❌ Error processing document: $e');
        }
      }

      debugPrint('\n📊 Final Results:');
      debugPrint('- Total poems: ${poems.length}');
      debugPrint('- Book IDs: ${poems.map((p) => p.bookId).toSet()}');
      
      return poems;

    } catch (e, stack) {
      debugPrint('❌ Query failed: $e\n$stack');
      return [];
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

  Future<List<Poem>> searchPoems(String query) async {
    try {
      debugPrint('🔍 Searching poems with query: $query');
      
      // Normalize query for both English and Urdu
      final normalizedQuery = _normalizeText(query);
      final List<String> searchTerms = _generateSearchTerms(normalizedQuery);
      
      debugPrint('Search terms: $searchTerms');

      // Query Firestore
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('poems')
          .where('search_terms', arrayContainsAny: searchTerms)
          .get();

      debugPrint('Found ${snapshot.docs.length} potential matches');

      final poems = <Poem>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (_isRelevantMatch(data, normalizedQuery)) {
            final poem = Poem.fromFirestore(doc);
            poems.add(poem);
          }
        } catch (e) {
          debugPrint('Error processing doc: $e');
        }
      }

      return poems;
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  Future<List<Poem>> getAllPoems() async {
    try {
      debugPrint('📚 Fetching all poems');
      
      final snapshot = await _firestore
          .collection('poems')
          .orderBy('_id')
          .get();

      final poems = <Poem>[];
      for (var doc in snapshot.docs) {
        try {
          final poem = Poem.fromFirestore(doc);
          poems.add(poem);
        } catch (e) {
          debugPrint('❌ Error parsing poem ${doc.id}: $e');
        }
      }

      debugPrint('📊 Loaded ${poems.length} total poems');
      return poems;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return [];
    }
  }

  String _normalizeText(String text) {
    return text
        .replaceAll('ی', 'ي')
        .replaceAll('ک', 'ك')
        .replaceAll('ہ', 'ه')
        .replaceAll('ئ', 'ي')
        .replaceAll('\u200C', '') // Remove zero-width non-joiner
        .replaceAll('\u200B', '') // Remove zero-width space
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim()
        .toLowerCase();
  }

  List<String> _generateSearchTerms(String query) {
    final terms = <String>[];
    // Add original query
    terms.add(query);
    
    // Add individual words
    terms.addAll(query.split(' '));
    
    // Add partial matches (for Urdu)
    if (query.length > 2) {
      for (int i = 2; i <= query.length; i++) {
        terms.add(query.substring(0, i));
      }
    }
    
    return terms.where((term) => term.isNotEmpty).toList();
  }

  bool _isRelevantMatch(Map<String, dynamic> data, String query) {
    final title = _normalizeText(data['title'] ?? '');
    final content = _normalizeText(data['data'] ?? '');
    
    return title.contains(query) || 
           content.contains(query) ||
           query.split(' ').every((word) => 
             title.contains(word) || content.contains(word)
           );
  }
}
