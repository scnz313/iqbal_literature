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
      // Normalize and prepare the query
      final normalizedQuery = _normalizeQuery(query);
      final isUrdu = _isUrduText(normalizedQuery);
      
      // Generate query variants for more flexible matching
      final queryVariants = _generateQueryVariants(normalizedQuery, isUrdu);

      final results = await Future.wait([
        _searchBooks(normalizedQuery, queryVariants, isUrdu: isUrdu, limit: limit),
        _searchPoems(normalizedQuery, queryVariants, isUrdu: isUrdu, limit: limit),
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

      final limitedResults = combinedResults.take(limit ?? 50).toList();
      
      debugPrint('📊 Search for "$query" found ${limitedResults.length} results');
      return limitedResults;
    } catch (e) {
      debugPrint('❌ Search error: $e');
      return [];
    }
  }

  // Generate variations of the query to improve search results
  List<String> _generateQueryVariants(String query, bool isUrdu) {
    final variants = <String>{query}; // Use a Set to avoid duplicates
    
    if (!isUrdu) {
      // For English queries, add variants with different word forms
      final words = query.split(' ');
      
      // Add individual words as variants for multi-word queries
      if (words.length > 1) {
        for (var word in words) {
          if (word.length > 2) { // Only add significant words
            variants.add(word);
          }
        }
      }
      
      // Add variants with stemming (basic implementation)
      for (var word in words) {
        if (word.endsWith('ing')) {
          variants.add(word.substring(0, word.length - 3)); // walk from walking
          variants.add(word.substring(0, word.length - 3) + 'e'); // make from making
        } else if (word.endsWith('ed')) {
          variants.add(word.substring(0, word.length - 2)); // walk from walked
          variants.add(word.substring(0, word.length - 1)); // love from loved
        } else if (word.endsWith('s') && !word.endsWith('ss')) {
          variants.add(word.substring(0, word.length - 1)); // singular from plural
        }
      }
    } else {
      // For Urdu, handle space variations and common prefixes/suffixes
      final words = query.split(' ');
      
      // Add individual words for multi-word queries
      if (words.length > 1) {
        for (var word in words) {
          if (word.length > 2) { // Only add significant words
            variants.add(word);
          }
        }
      }
    }
    
    return variants.toList();
  }

  Future<List<SearchResult>> _searchBooks(
      String query, 
      List<String> queryVariants,
      {required bool isUrdu, int? limit}) async {
    final books = await _getCachedBooks();
    final results = <SearchResult>[];

    for (final book in books) {
      final bookName = isUrdu ? book['name'] : book['name'].toLowerCase();
      final bookDescription = isUrdu ? book['description'] ?? '' : (book['description'] ?? '').toLowerCase();
      
      // Try to match with the main query
      var score = _calculateMatchScore(
        searchText: bookName, 
        query: query,
        isUrdu: isUrdu,
      );
      
      // If no match with title, try description
      if (score <= 0) {
        score = _calculateMatchScore(
          searchText: bookDescription,
          query: query,
          isUrdu: isUrdu,
        ) * 0.8; // Lower relevance for description matches
      }
      
      // If still no match, try with query variants on title
      if (score <= 0) {
        for (var variant in queryVariants) {
          final variantScore = _calculateMatchScore(
            searchText: bookName,
            query: variant,
            isUrdu: isUrdu,
          ) * 0.9; // Slightly lower relevance for variant matches
          
          if (variantScore > score) {
            score = variantScore;
          }
        }
      }

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

  Future<List<SearchResult>> _searchPoems(
      String query, 
      List<String> queryVariants,
      {required bool isUrdu, int? limit}) async {
    final poems = await _getCachedPoems();
    final results = <SearchResult>[];

    for (final poem in poems) {
      // Check title match
      final poemTitle = isUrdu ? poem['title'] : poem['title'].toLowerCase();
      final poemData = poem['data'] ?? '';
      
      var titleScore = _calculateMatchScore(
        searchText: poemTitle,
        query: query,
        isUrdu: isUrdu,
      );

      // If no match in title, check with variants
      if (titleScore <= 0) {
        for (var variant in queryVariants) {
          final variantScore = _calculateMatchScore(
            searchText: poemTitle,
            query: variant,
            isUrdu: isUrdu,
          ) * 0.9; // Slightly lower relevance for variant matches
          
          if (variantScore > titleScore) {
            titleScore = variantScore;
          }
        }
      }

      if (titleScore > 0) {
        results.add(SearchResult(
          id: poem['id'] ?? '',
          title: poem['title'] ?? '',
          subtitle: _extractPreview(poemData),
          type: SearchResultType.poem,
          relevance: titleScore,
          highlight: _extractMatchingText(poem['title'], query, isUrdu),
        ));
        continue;
      }

      // Check content match
      final matchingLine = _findBestMatchingLine(poemData, query, queryVariants, isUrdu);
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
      // For Urdu text, use more specific matching logic
      if (searchText == query) {
        return 1.0; // Exact match
      }
      if (searchText.contains(query)) {
        return 0.9; // Contains exact query
      }
      
      // For partial matches in Urdu with word boundaries
      for (var word in query.split(' ')) {
        if (word.length > 2) {
          if (searchText.split(' ').contains(word)) {
            return 0.8; // Contains exact word
          }
          if (searchText.contains(word)) {
            return 0.7; // Contains word as substring
          }
        }
      }
    } else {
      // For English text, use more flexible matching
      if (searchText.toLowerCase() == query.toLowerCase()) {
        return 1.0; // Exact match (case insensitive)
      }
      if (searchText.toLowerCase().contains(query.toLowerCase())) {
        return 0.9; // Contains exact query (case insensitive)
      }
      
      // Check if the search text contains all words from the query
      final queryWords = query.toLowerCase().split(' ').where((w) => w.length > 2).toList();
      final searchWords = searchText.toLowerCase().split(' ').where((w) => w.length > 2).toList();
      
      if (queryWords.isNotEmpty) {
        int matchedWords = 0;
        for (var word in queryWords) {
          if (searchWords.contains(word)) {
            matchedWords++;
          }
        }
        
        if (matchedWords == queryWords.length) {
          return 0.85; // All query words found in exact form
        }
        
        if (matchedWords > 0) {
          return 0.6 * (matchedWords / queryWords.length); // Partial word matches
        }
      }
      
      // Check for partial word matches
      for (var word in query.toLowerCase().split(' ')) {
        if (word.length > 2) {
          for (var searchWord in searchWords) {
            final similarity = _calculateSimilarity(searchWord, word);
            if (similarity > 0.8) {
              return 0.5 * similarity; // Close word match
            }
          }
        }
      }
    }

    return 0;
  }

  ({String line, double score})? _findBestMatchingLine(
      String text, String query, List<String> queryVariants, bool isUrdu) {
    var bestMatch = (line: '', score: 0.0);

    for (var line in text.split('\n')) {
      final normalizedLine = isUrdu ? line.trim() : line.trim().toLowerCase();
      if (normalizedLine.isEmpty) continue;

      // Try with main query
      var score = _calculateMatchScore(
        searchText: normalizedLine,
        query: query,
        isUrdu: isUrdu,
      );

      // If no match, try with query variants
      if (score <= 0) {
        for (var variant in queryVariants) {
          final variantScore = _calculateMatchScore(
            searchText: normalizedLine,
            query: variant,
            isUrdu: isUrdu,
          ) * 0.9; // Slightly lower score for variants
          
          if (variantScore > score) {
            score = variantScore;
          }
        }
      }

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
    try {
      if (_cachedBooks == null || _cachedBooks!.isEmpty) {
        final snapshot = await _firestore.collection('books').get();
        _cachedBooks = snapshot.docs.map((doc) {
          final data = doc.data();
          // Ensure required fields exist with defaults
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unnamed Book',
            'description': data['description'] ?? '',
            ...data,
          };
        }).toList();
        debugPrint('📚 Loaded ${_cachedBooks!.length} books for search');
      }
      return _cachedBooks ?? [];
    } catch (e) {
      debugPrint('❌ Error fetching books: $e');
      // Return empty list instead of null to avoid null errors
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedPoems() async {
    try {
      if (_cachedPoems == null || _cachedPoems!.isEmpty) {
        final snapshot = await _firestore.collection('poems').get();
        _cachedPoems = snapshot.docs.map((doc) {
          final data = doc.data();
          // Ensure required fields exist with defaults
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled Poem',
            'data': data['data'] ?? '',
            ...data,
          };
        }).toList();
        debugPrint('📝 Loaded ${_cachedPoems!.length} poems for search');
      }
      return _cachedPoems ?? [];
    } catch (e) {
      debugPrint('❌ Error fetching poems: $e');
      // Return empty list instead of null to avoid null errors
      return [];
    }
  }

  String _extractMatchingText(String text, String query, bool isUrdu) {
    // If the text is very short, just return it
    if (text.length < 100) return text;
    
    final searchIndex = isUrdu
        ? text.indexOf(query)
        : text.toLowerCase().indexOf(query.toLowerCase());
        
    if (searchIndex == -1) {
      // If exact match not found, look for matching words
      final words = isUrdu ? 
          text.split(' ') : 
          text.toLowerCase().split(' ');
      final queryWords = isUrdu ? 
          query.split(' ') : 
          query.toLowerCase().split(' ');
          
      for (var qWord in queryWords) {
        if (qWord.length < 3) continue; // Skip short words
        
        for (int i = 0; i < words.length; i++) {
          if (words[i].contains(qWord)) {
            // Found a matching word - extract context
            final start = i > 5 ? i - 5 : 0;
            final end = i + 5 < words.length ? i + 5 : words.length - 1;
            
            return '...${words.sublist(start, end + 1).join(' ')}...';
          }
        }
      }
      
      // If still no good context, return beginning of text
      return '${text.substring(0, min(100, text.length))}...';
    }
    
    // Found exact match, extract context around it
    final start = searchIndex > 50 ? searchIndex - 50 : 0;
    final end = text.length > searchIndex + query.length + 50 
        ? searchIndex + query.length + 50 
        : text.length;
    
    return '...${text.substring(start, end)}...';
  }

  String _extractPreview(String text, [String? query]) {
    if (text.isEmpty) return '';
    
    if (query != null && query.isNotEmpty) {
      // Try to find context around the query
      final index = text.toLowerCase().indexOf(query.toLowerCase());
      if (index >= 0) {
        final start = index > 50 ? index - 50 : 0;
        final end = index + 100 < text.length ? index + 100 : text.length;
        return '...${text.substring(start, end)}...';
      }
    }
    
    // Default preview of beginning
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  void clearCache() {
    _cachedBooks = null;
    _cachedPoems = null;
    debugPrint('🧹 Search cache cleared');
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;

    // For very short strings (like 1-2 chars), exact matching is better
    if (s1.length <= 2 || s2.length <= 2) {
      return s1 == s2 ? 1.0 : 0.0;
    }

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    final longerLength = longer.length;
    if (longerLength == 0) return 1.0;

    // Use Levenshtein distance to calculate string similarity
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
            newValue = [newValue, lastValue, costs[j]].reduce(min) + 1;
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
