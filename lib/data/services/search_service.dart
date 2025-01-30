import 'package:flutter/foundation.dart';  // Add this for debugPrint
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/search/widgets/search_result.dart';

class SearchService {
  final FirebaseFirestore _firestore;
  
  SearchService(this._firestore);

  Future<List<SearchResult>> search(String query, {int? limit}) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('🔍 Searching for: $query');
      final normalizedQuery = _normalizeQuery(query);
      
      // Search in parallel across collections
      final results = await Future.wait([
        _searchBooks(normalizedQuery, limit: limit),
        _searchPoems(normalizedQuery, limit: limit),
        _searchLines(normalizedQuery, limit: limit),
      ]);

      // Combine and sort results
      final combinedResults = [
        ...results[0], // books
        ...results[1], // poems
        ...results[2], // lines
      ];

      // Sort by relevance
      combinedResults.sort((a, b) => b.relevance.compareTo(a.relevance));
      
      return combinedResults;
    } catch (e) {
      debugPrint('❌ Search error: $e');
      return [];
    }
  }

  String _normalizeQuery(String query) {
    // Normalize Urdu text
    return query
      .replaceAll('ی', 'ي')
      .replaceAll('ک', 'ك')
      .trim();
  }

  Future<List<SearchResult>> _searchBooks(String query, {int? limit}) async {
    final snapshot = await _firestore
        .collection('books')
        .where('search_terms', arrayContains: query.toLowerCase())
        .limit(limit ?? 10)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SearchResult(
        id: doc.id,
        title: data['name'],
        subtitle: data['description'] ?? '',
        type: SearchResultType.book,
        relevance: _calculateRelevance(query, data['name']),
        highlight: _getHighlight(query, data['name']),
      );
    }).toList();
  }

  Future<List<SearchResult>> _searchPoems(String query, {int? limit}) async {
    final snapshot = await _firestore
        .collection('poems')
        .where('search_content', arrayContains: query.toLowerCase())
        .limit(limit ?? 10)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SearchResult(
        id: doc.id,
        title: data['title'],
        subtitle: _extractMatchingLine(query, data['data']),
        type: SearchResultType.poem,
        relevance: _calculateRelevance(query, data['data']),
        highlight: _getHighlight(query, data['data']),
      );
    }).toList();
  }

  Future<List<SearchResult>> _searchLines(String query, {int? limit}) async {
    final snapshot = await _firestore
        .collection('lines')
        .where('text', arrayContains: query.toLowerCase())
        .limit(limit ?? 10)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SearchResult(
        id: doc.id,
        title: data['text'] ?? '',
        subtitle: '',
        type: SearchResultType.line,
        relevance: _calculateRelevance(query, data['text'] ?? ''),
        highlight: _getHighlight(query, data['text'] ?? ''),
      );
    }).toList();
  }

  double _calculateRelevance(String query, String content) {
    // Simple relevance calculation
    final normalizedQuery = query.toLowerCase();
    final normalizedContent = content.toLowerCase();
    
    double score = 0;
    
    // Exact match gets highest score
    if (normalizedContent.contains(normalizedQuery)) {
      score += 1.0;
    }
    
    // Word match gets medium score
    final queryWords = normalizedQuery.split(' ');
    final contentWords = normalizedContent.split(' ');
    
    for (var word in queryWords) {
      if (contentWords.contains(word)) {
        score += 0.5;
      }
    }

    return score;
  }

  String _getHighlight(String query, String content) {
    // Find the matching section with some context
    final index = content.toLowerCase().indexOf(query.toLowerCase());
    if (index == -1) return '';

    final start = index > 20 ? index - 20 : 0;
    final end = index + query.length + 20 < content.length 
        ? index + query.length + 20 
        : content.length;

    return '...${content.substring(start, end)}...';
  }

  String _extractMatchingLine(String query, String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains(query.toLowerCase())) {
        return line.trim();
      }
    }
    return '';
  }
}
