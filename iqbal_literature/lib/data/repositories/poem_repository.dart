import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../features/poems/models/poem.dart';
import '../models/line/line.dart';
import '../historical_context_data.dart';

class PoemRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'poems';
  static const String _cacheBoxName = 'poems_cache';
  static const String _allPoemsKey = 'all_poems';
  static const String _poemsByBookKey = 'poems_by_book_';
  static const String _linesByPoemKey = 'lines_by_poem_';
  static const String _searchResultsKey = 'search_results_';
  static const Duration _cacheDuration = Duration(days: 7);

  late Box _cacheBox;
  bool _isCacheInitialized = false;

  PoemRepository(this._firestore);

  Future<void> _initCache() async {
    if (_isCacheInitialized) return;
    _cacheBox = await Hive.openBox(_cacheBoxName);
    _isCacheInitialized = true;
  }

  Future<List<Poem>> getPoemsByBookId(int bookId) async {
    await _initCache();
    final cacheKey = '${_poemsByBookKey}$bookId';

    // Try to get from cache first
    final cachedData = _cacheBox.get(cacheKey);
    if (cachedData != null) {
      final cacheTime = _cacheBox.get('${cacheKey}_time');
      if (cacheTime != null) {
        final cachedAt = DateTime.parse(cacheTime);
        if (DateTime.now().difference(cachedAt) < _cacheDuration) {
          debugPrint('📦 Using cached poems for book ID: $bookId');
          try {
            final List<dynamic> data = cachedData;
            return data
                .map((item) => Poem.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          } catch (e) {
            debugPrint('❌ Error deserializing cached poems: $e');
            // Continue to fetch from Firestore on cache error
          }
        }
      }
    }

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

      // Cache the result
      if (poems.isNotEmpty) {
        try {
          final serializableData = poems.map((poem) => poem.toMap()).toList();
          await _cacheBox.put(cacheKey, serializableData);
          await _cacheBox.put(
              '${cacheKey}_time', DateTime.now().toIso8601String());
          debugPrint('📦 Cached ${poems.length} poems for book ID: $bookId');
        } catch (e) {
          debugPrint('❌ Error caching poems: $e');
        }
      }

      return poems;
    } catch (e, stack) {
      debugPrint('❌ Query failed: $e\n$stack');
      return [];
    }
  }

  Future<List<Line>> getLinesByPoemId(int poemId) async {
    await _initCache();
    final cacheKey = '${_linesByPoemKey}$poemId';

    // Try to get from cache first
    final cachedData = _cacheBox.get(cacheKey);
    if (cachedData != null) {
      final cacheTime = _cacheBox.get('${cacheKey}_time');
      if (cacheTime != null) {
        final cachedAt = DateTime.parse(cacheTime);
        if (DateTime.now().difference(cachedAt) < _cacheDuration) {
          debugPrint('📦 Using cached lines for poem ID: $poemId');
          try {
            final List<dynamic> data = cachedData;
            return data
                .map((item) => Line.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          } catch (e) {
            debugPrint('❌ Error deserializing cached lines: $e');
            // Continue to fetch from Firestore on cache error
          }
        }
      }
    }

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

      final lines =
          snapshot.docs.map((doc) => Line.fromFirestore(doc)).toList();

      // Cache the result
      if (lines.isNotEmpty) {
        try {
          final serializableData = lines.map((line) => line.toMap()).toList();
          await _cacheBox.put(cacheKey, serializableData);
          await _cacheBox.put(
              '${cacheKey}_time', DateTime.now().toIso8601String());
          debugPrint('📦 Cached ${lines.length} lines for poem ID: $poemId');
        } catch (e) {
          debugPrint('❌ Error caching lines: $e');
        }
      }

      return lines;
    } catch (e) {
      debugPrint('Error fetching lines: $e');
      return [];
    }
  }

  Future<List<Poem>> searchPoems(String query) async {
    await _initCache();
    final normalizedQuery = _normalizeText(query);
    final cacheKey = '${_searchResultsKey}${normalizedQuery.hashCode}';

    // Try to get from cache first
    final cachedData = _cacheBox.get(cacheKey);
    if (cachedData != null) {
      final cacheTime = _cacheBox.get('${cacheKey}_time');
      if (cacheTime != null) {
        final cachedAt = DateTime.parse(cacheTime);
        if (DateTime.now().difference(cachedAt) < _cacheDuration) {
          debugPrint('📦 Using cached search results for query: $query');
          try {
            final List<dynamic> data = cachedData;
            return data
                .map((item) => Poem.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          } catch (e) {
            debugPrint('❌ Error deserializing cached search results: $e');
            // Continue to fetch from Firestore on cache error
          }
        }
      }
    }

    try {
      debugPrint('🔍 Searching poems with query: $query');

      // Normalize query for both English and Urdu
      final searchTerms = _generateSearchTerms(normalizedQuery);

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

      // Cache the results
      if (poems.isNotEmpty) {
        try {
          final serializableData = poems.map((poem) => poem.toMap()).toList();
          await _cacheBox.put(cacheKey, serializableData);
          await _cacheBox.put(
              '${cacheKey}_time', DateTime.now().toIso8601String());
          debugPrint(
              '📦 Cached ${poems.length} search results for query: $query');
        } catch (e) {
          debugPrint('❌ Error caching search results: $e');
        }
      }

      return poems;
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  Future<List<Poem>> getAllPoems() async {
    await _initCache();

    // Try to get from cache first
    final cachedData = _cacheBox.get(_allPoemsKey);
    if (cachedData != null) {
      final cacheTime = _cacheBox.get('${_allPoemsKey}_time');
      if (cacheTime != null) {
        final cachedAt = DateTime.parse(cacheTime);
        if (DateTime.now().difference(cachedAt) < _cacheDuration) {
          debugPrint('📦 Using cached all poems list');
          try {
            final List<dynamic> data = cachedData;
            return data
                .map((item) => Poem.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          } catch (e) {
            debugPrint('❌ Error deserializing cached poems: $e');
            // Continue to fetch from Firestore on cache error
          }
        }
      }
    }

    try {
      debugPrint('📚 Fetching all poems');

      final snapshot =
          await _firestore.collection('poems').orderBy('_id').get();

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

      // Cache the result
      if (poems.isNotEmpty) {
        try {
          final serializableData = poems.map((poem) => poem.toMap()).toList();
          await _cacheBox.put(_allPoemsKey, serializableData);
          await _cacheBox.put(
              '${_allPoemsKey}_time', DateTime.now().toIso8601String());
          debugPrint('📦 Cached ${poems.length} poems for all poems list');
        } catch (e) {
          debugPrint('❌ Error caching all poems: $e');
        }
      }

      return poems;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getHistoricalContext(int poemId) async {
    try {
      final box = await Hive.openBox('historical_context');
      final data = await box.get(poemId.toString());
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      debugPrint('❌ Cache read error: $e');
      return null;
    }
  }

  Future<void> saveHistoricalContext(
      int poemId, Map<String, dynamic> data) async {
    try {
      final box = await Hive.openBox('historical_context');
      await box.put(poemId.toString(), data);
    } catch (e) {
      debugPrint('❌ Cache write error: $e');
    }
  }

  Future<void> clearCache() async {
    await _initCache();
    await _cacheBox.clear();
    debugPrint('🧹 Poem cache cleared');
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
        query
            .split(' ')
            .every((word) => title.contains(word) || content.contains(word));
  }
}
