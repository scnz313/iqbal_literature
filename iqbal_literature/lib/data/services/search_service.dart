import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/search/widgets/search_result.dart';
import 'dart:math' show min;

class SearchService {
  final FirebaseFirestore _firestore;
  List<Map<String, dynamic>>? _cachedBooks;
  List<Map<String, dynamic>>? _cachedPoems;
  
  SearchService(this._firestore);

  Future<List<SearchResult>> search(String query, {int? limit}) async {
    if (query.trim().isEmpty) return [];

    try {
      final normalizedQuery = _normalizeQuery(query);
      final isUrdu = _isUrduText(normalizedQuery);
      
      final results = await Future.wait([
        _searchBooks(normalizedQuery, isUrdu: isUrdu, limit: limit),
        _searchPoems(normalizedQuery, isUrdu: isUrdu, limit: limit),
      ]);

      final combinedResults = [
        ...results[0],
        ...results[1],
      ]..sort((a, b) {
        // First sort by relevance
        final byRelevance = b.relevance.compareTo(a.relevance);
        if (byRelevance != 0) return byRelevance;
        
        // Then by type (books first, then poems, then lines)
        return a.type.index.compareTo(b.type.index);
      });

      return combinedResults.take(limit ?? 20).toList();
    } catch (e) {
      debugPrint('❌ Search error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchBooks(String query, {required bool isUrdu, int? limit}) async {
    final books = await _getCachedBooks();
    final results = <SearchResult>[];
    
    for (final book in books) {
      final score = _calculateMatchScore(
        searchText: isUrdu ? book['name'] : book['name'].toLowerCase(),
        query: query,
        isUrdu: isUrdu,
      );
      
      if (score > 0) {
        results.add(SearchResult(
          id: book['id'] ?? '',
          title: book['name'] ?? '',
          subtitle: book['description'] ?? '',
          type: SearchResultType.book,
          relevance: score,
          highlight: _extractMatchingText(book['name'], query, isUrdu),
        ));
      }
    }
    
    return results;
  }

  Future<List<SearchResult>> _searchPoems(String query, {required bool isUrdu, int? limit}) async {
    final poems = await _getCachedPoems();
    final results = <SearchResult>[];
    
    for (final poem in poems) {
      // Check title match
      var titleScore = _calculateMatchScore(
        searchText: isUrdu ? poem['title'] : poem['title'].toLowerCase(),
        query: query,
        isUrdu: isUrdu,
      );
      
      if (titleScore > 0) {
        results.add(SearchResult(
          id: poem['id'] ?? '',
          title: poem['title'] ?? '',
          subtitle: _extractPreview(poem['data']),
          type: SearchResultType.poem,
          relevance: titleScore,
          highlight: _extractMatchingText(poem['title'], query, isUrdu),
        ));
        continue;
      }
      
      // Check content match
      final matchingLine = _findBestMatchingLine(poem['data'], query, isUrdu);
      if (matchingLine != null) {
        results.add(SearchResult(
          id: poem['id'] ?? '',
          title: poem['title'] ?? '',
          subtitle: matchingLine.line,
          type: SearchResultType.line,
          relevance: matchingLine.score,
          highlight: matchingLine.line,
        ));
      }
    }
    
    return results;
  }

  double _calculateMatchScore({
    required String searchText,
    required String query,
    required bool isUrdu,
  }) {
    if (searchText.isEmpty || query.isEmpty) return 0;
    
    if (isUrdu) {
      // For Urdu text, use contains for exact matching
      if (searchText.contains(query)) {
        return 1.0;
      }
      // For partial matches in Urdu
      for (var word in query.split(' ')) {
        if (word.length > 2 && searchText.contains(word)) {
          return 0.7;
        }
      }
    } else {
      // For English text, use more flexible matching
      final similarity = _calculateSimilarity(searchText, query);
      if (similarity > 0.8) return similarity;
      
      // Check for partial word matches
      for (var word in query.split(' ')) {
        if (word.length > 2 && searchText.contains(word)) {
          return 0.6;
        }
      }
    }
    
    return 0;
  }

  ({String line, double score})? _findBestMatchingLine(String text, String query, bool isUrdu) {
    var bestMatch = (line: '', score: 0.0);
    
    for (var line in text.split('\n')) {
      final normalizedLine = isUrdu ? line.trim() : line.trim().toLowerCase();
      if (normalizedLine.isEmpty) continue;
      
      final score = _calculateMatchScore(
        searchText: normalizedLine,
        query: query,
        isUrdu: isUrdu,
      );
      
      if (score > bestMatch.score) {
        bestMatch = (line: line.trim(), score: score);
      }
    }
    
    return bestMatch.score > 0 ? bestMatch : null;
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

  Future<List<Map<String, dynamic>>> _getCachedBooks() async {
    if (_cachedBooks == null) {
      final snapshot = await _firestore.collection('books').get();
      _cachedBooks = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    }
    return _cachedBooks!;
  }

  Future<List<Map<String, dynamic>>> _getCachedPoems() async {
    if (_cachedPoems == null) {
      final snapshot = await _firestore.collection('poems').get();
      _cachedPoems = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    }
    return _cachedPoems!;
  }

  String _extractMatchingText(String text, String query, bool isUrdu) {
    final searchIndex = isUrdu
        ? text.indexOf(query)
        : text.toLowerCase().indexOf(query.toLowerCase());
    if (searchIndex == -1) return '';

    final start = searchIndex > 50 ? searchIndex - 50 : 0;
    final end = text.length > searchIndex + 50 ? searchIndex + 50 : text.length;
    return '...${text.substring(start, end)}...';
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

  void clearCache() {
    _cachedBooks = null;
    _cachedPoems = null;
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    final longerLength = longer.length;
    if (longerLength == 0) return 1.0;

    return (longerLength - _levenshteinDistance(longer, shorter)) / 
           longerLength.toDouble();
  }

  int _levenshteinDistance(String s1, String s2) {
    var costs = List<int>.filled(s2.length + 1, 0);

    for (var i = 0; i <= s1.length; i++) {
      var lastValue = i;
      for (var j = 0; j <= s2.length; j++) {
        if (i == 0) {
          costs[j] = j;
        } else if (j > 0) {
          var newValue = costs[j - 1];
          if (s1[i - 1] != s2[j - 1]) {
            newValue = [newValue, lastValue, costs[j]]
                .reduce(min) + 1;
          }
          costs[j - 1] = lastValue;
          lastValue = newValue;
        }
      }
      if (i > 0) costs[s2.length] = lastValue;
    }
    return costs[s2.length];
  }
}
