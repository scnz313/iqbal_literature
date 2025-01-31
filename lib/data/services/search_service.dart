import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/search/widgets/search_result.dart';

class SearchService {
  final FirebaseFirestore _firestore;
  
  SearchService(this._firestore);

  Future<List<SearchResult>> search(String query, {int? limit}) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('🔍 Starting search for: $query');
      final normalizedQuery = _normalizeQuery(query);
      
      // Search across all collections
      final results = await Future.wait([
        _searchBooks(normalizedQuery, limit: limit),
        _searchPoems(normalizedQuery, limit: limit),
        _searchLines(normalizedQuery, limit: limit),
      ]);

      debugPrint('📚 Found ${results[0].length} books');
      debugPrint('📝 Found ${results[1].length} poems');
      debugPrint('📄 Found ${results[2].length} lines');

      final combinedResults = [
        ...results[0],
        ...results[1],
        ...results[2],
      ];

      debugPrint('📊 Total results: ${combinedResults.length}');
      return combinedResults;
    } catch (e) {
      debugPrint('❌ Search error: $e');
      return [];
    }
  }

  String _normalizeQuery(String query) {
    return query.trim();
  }

  Future<List<SearchResult>> _searchBooks(String query, {int? limit}) async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(limit ?? 10)
          .get();

      debugPrint('📚 Searching books: ${snapshot.docs.length} results');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SearchResult(
          id: doc.id,
          title: data['name'] ?? '',
          subtitle: data['description'] ?? '',
          type: SearchResultType.book,
          relevance: 1.0,
          highlight: '',
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Book search error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchPoems(String query, {int? limit}) async {
    try {
      // Search in both title and content
      final titleSnapshot = await _firestore
          .collection('poems')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .limit(limit ?? 10)
          .get();

      final contentSnapshot = await _firestore
          .collection('poems')
          .where('data', isGreaterThanOrEqualTo: query)
          .where('data', isLessThan: query + 'z')
          .limit(limit ?? 10)
          .get();

      debugPrint('📝 Searching poems: ${titleSnapshot.docs.length + contentSnapshot.docs.length} results');

      // Combine results
      final results = <SearchResult>[];
      
      // Add title matches
      results.addAll(titleSnapshot.docs.map((doc) {
        final data = doc.data();
        return SearchResult(
          id: doc.id,
          title: data['title'] ?? '',
          subtitle: _extractPreview(data['data'] ?? ''),
          type: SearchResultType.poem,
          relevance: 1.0,
          highlight: '',
        );
      }));

      // Add content matches
      results.addAll(contentSnapshot.docs.map((doc) {
        final data = doc.data();
        return SearchResult(
          id: doc.id,
          title: data['title'] ?? '',
          subtitle: _extractPreview(data['data'] ?? '', query),
          type: SearchResultType.poem,
          relevance: 0.8,
          highlight: '',
        );
      }));

      return results;
    } catch (e) {
      debugPrint('❌ Poem search error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchLines(String query, {int? limit}) async {
    try {
      final snapshot = await _firestore
          .collection('poems')
          .where('data', isGreaterThanOrEqualTo: query)
          .where('data', isLessThan: query + 'z')
          .limit(limit ?? 10)
          .get();

      debugPrint('📄 Searching lines: ${snapshot.docs.length} results');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final matchingLine = _findMatchingLine(data['data'] ?? '', query);
        return SearchResult(
          id: doc.id,
          title: matchingLine,
          subtitle: data['title'] ?? '',
          type: SearchResultType.line,
          relevance: 0.5,
          highlight: '',
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Line search error: $e');
      return [];
    }
  }

  String _extractPreview(String text, [String? query]) {
    if (query != null) {
      final index = text.toLowerCase().indexOf(query.toLowerCase());
      if (index >= 0) {
        final start = index > 50 ? index - 50 : 0;
        final end = index + 100 < text.length ? index + 100 : text.length;
        return '...${text.substring(start, end)}...';
      }
    }
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  String _findMatchingLine(String text, String query) {
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains(query.toLowerCase())) {
        return line.trim();
      }
    }
    return '';
  }
}
