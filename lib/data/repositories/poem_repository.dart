import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poem/poem.dart';
import '../models/line/line.dart';

class PoemRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'poems';

  PoemRepository(this._firestore);

  Future<List<Poem>> getAllPoems() async {
    try {
      debugPrint('📚 Fetching all poems');

      // Remove any limit and fetch all documents
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('poems')
          .orderBy('_id')
          .get();  // No limit here

      debugPrint('📝 Total poems found: ${snapshot.docs.length}');

      final poems = snapshot.docs.map((doc) {
        try {
          final poem = Poem.fromFirestore(doc);
          debugPrint('Processing poem ${poem.id}: ${poem.title}');
          return poem;
        } catch (e) {
          debugPrint('❌ Error parsing poem ${doc.id}: $e');
          return null;
        }
      }).whereType<Poem>().toList();

      // Sort poems by _id if needed
      poems.sort((a, b) => a.id.compareTo(b.id));

      debugPrint('✅ Successfully loaded ${poems.length} poems');
      return poems;

    } catch (e) {
      debugPrint('❌ Error fetching all poems: $e');
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
      debugPrint('🔥 FIRESTORE QUERY: book_id=$bookId (${bookId.runtimeType})');

      // Ensure we're querying with an integer
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('poems')
          .where('book_id', isEqualTo: bookId)
          .orderBy('_id')
          .get();

      debugPrint('📝 Raw query returned ${snapshot.docs.length} documents');

      // Debug each document
      snapshot.docs.forEach((doc) {
        final data = doc.data();
        debugPrint('📄 Poem ${doc.id}:');
        debugPrint('  - book_id: ${data['book_id']} (${data['book_id'].runtimeType})');
        debugPrint('  - title: ${data['title']}');
      });

      // Process with strict type checking
      final poems = <Poem>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final docBookId = data['book_id'];
          
          // Ensure exact numeric match
          if (docBookId is int && docBookId == bookId) {
            final poem = Poem.fromFirestore(doc);
            poems.add(poem);
            debugPrint('✅ Added poem: ${poem.title}');
          } else {
            debugPrint('❌ Skipped poem ${doc.id} - wrong book_id type or value');
          }
        } catch (e) {
          debugPrint('❌ Error processing doc: $e');
        }
      }

      // Final validation
      final uniqueBookIds = poems.map((p) => p.bookId).toSet();
      debugPrint('📊 Results:');
      debugPrint('- Total poems: ${poems.length}');
      debugPrint('- Unique book IDs: $uniqueBookIds');

      return poems;
    } catch (e) {
      debugPrint('❌ Query Error: $e');
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
