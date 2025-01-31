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
      ]);

      debugPrint('📚 Found ${results[0].length} books');
      debugPrint('📝 Found ${results[1].length} poems');

      final combinedResults = [
        ...results[0],
        ...results[1],
      ];

      debugPrint('📊 Total results: ${combinedResults.length}');
      return combinedResults;
    } catch (e) {
      debugPrint('❌ Search error: $e');
      return [];
    }
  }

  String _normalizeQuery(String query) {
    final normalized = query.trim();
    
    // Don't lowercase Urdu text
    if (_isUrduText(normalized)) {
      return normalized;
    }
    
    return normalized.toLowerCase();
  }

  bool _isUrduText(String text) {
    return text.contains(RegExp(r'[\u0600-\u06FF]'));
  }

  Future<List<SearchResult>> _searchBooks(String query, {int? limit}) async {
    try {
      debugPrint('📚 Starting book search for query: $query');
      
      // Get all books and filter in memory
      final snapshot = await _firestore
          .collection('books')
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        final searchText = query.toLowerCase();
        
        return name.contains(searchText) || description.contains(searchText);
      }).map((doc) {
        final data = doc.data();
        debugPrint('📖 Book found: ${data['name']}');
        return SearchResult(
          id: doc.id,
          title: data['name'] ?? '',
          subtitle: data['description'] ?? '',
          type: SearchResultType.book,
          relevance: 1.0,
          highlight: '',
        );
      }).toList();

      debugPrint('📚 Found ${results.length} books');
      return results.take(limit ?? 10).toList();
    } catch (e) {
      debugPrint('❌ Book search error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchPoems(String query, {int? limit}) async {
    try {
      debugPrint('📝 Starting poem search for query: $query');
      
      // Get all poems and filter in memory
      final snapshot = await _firestore
          .collection('poems')
          .get();

      final results = <SearchResult>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final content = (data['data'] ?? '').toString().toLowerCase();
        final searchText = query.toLowerCase();

        // Check title match
        if (title.contains(searchText)) {
          debugPrint('📜 Poem found by title: ${data['title']}');
          results.add(SearchResult(
            id: doc.id,
            title: data['title'] ?? '',
            subtitle: _extractPreview(data['data'] ?? ''),
            type: SearchResultType.poem,
            relevance: 1.0,
            highlight: '',
          ));
        }
        // Check content match
        else if (content.contains(searchText)) {
          final matchingLine = _findMatchingLine(data['data'] ?? '', query);
          if (matchingLine.isNotEmpty) {
            debugPrint('📜 Poem found by content: ${data['title']} - Line: $matchingLine');
            results.add(SearchResult(
              id: doc.id,
              title: data['title'] ?? '',
              subtitle: matchingLine,
              type: SearchResultType.line,
              relevance: 0.8,
              highlight: '',
            ));
          }
        }
      }

      return results.take(limit ?? 10).toList();
    } catch (e) {
      debugPrint('❌ Poem search error: $e');
      return [];
    }
  }

  String _findMatchingLine(String text, String query) {
    final lines = text.split('\n');
    
    for (var line in lines) {
      if (line.toLowerCase().contains(query.toLowerCase())) {
        debugPrint('📌 Found matching line: $line');
        return line.trim();
      }
    }
    return '';
  }

  List<String> _createSearchTerms(String query) {
    final normalized = _normalizeQuery(query);
    final terms = normalized.split(' ')
      .where((term) => term.isNotEmpty)
      .map((term) => term.toLowerCase())
      .toList();
    
    // Add the full query as a term
    terms.add(normalized.toLowerCase());
    
    // For Urdu text, add variations
    if (query.contains(RegExp(r'[\u0600-\u06FF]'))) {
      terms.addAll([
        normalized.replaceAll('ی', 'ي'),
        normalized.replaceAll('ک', 'ك'),
        normalized.replaceAll('ی', 'ي').replaceAll('ک', 'ك'),
      ]);
    }
    
    return terms;
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
}
