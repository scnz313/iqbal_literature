import 'package:flutter/material.dart';  // Add this import for Icons and IconData

enum SearchResultType { book, poem, line }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final double relevance;
  final String highlight;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.relevance,
    required this.highlight,
  });

  // Helper for UI
  String get typeLabel {
    switch (type) {
      case SearchResultType.book:
        return 'Book';
      case SearchResultType.poem:
        return 'Poem';
      case SearchResultType.line:
        return 'Line';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case SearchResultType.book:
        return Icons.book;
      case SearchResultType.poem:
        return Icons.article;
      case SearchResultType.line:
        return Icons.format_quote;
    }
  }
}
