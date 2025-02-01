import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

@immutable
class Poem extends Equatable {
  final int id;
  final String title;
  final String data;
  final int bookId;

  const Poem({
    required this.id,
    required this.title,
    required this.data,
    required this.bookId,
  });

  factory Poem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // Validate required fields
      final rawId = data['_id'];
      final rawBookId = data['book_id'];

      if (rawId == null || rawBookId == null) {
        throw FormatException('Missing required fields: _id or book_id');
      }

      // Parse and validate book_id
      final int bookId;
      if (rawBookId is int) {
        bookId = rawBookId;
      } else if (rawBookId is num) {
        bookId = rawBookId.toInt();
      } else {
        throw FormatException('Invalid book_id type: ${rawBookId.runtimeType}');
      }

      // Parse and validate _id
      final int id;
      if (rawId is int) {
        id = rawId;
      } else if (rawId is num) {
        id = rawId.toInt();
      } else {
        throw FormatException('Invalid _id type: ${rawId.runtimeType}');
      }

      return Poem(
        id: id,
        title: data['title']?.toString() ?? '',
        data: data['data']?.toString() ?? '',
        bookId: bookId,
      );
    } catch (e) {
      debugPrint('❌ Error parsing poem: $e');
      rethrow;
    }
  }

  factory Poem.fromMap(Map<String, dynamic> map) {
    return Poem(
      id: map['_id'] ?? 0,
      title: map['title'] ?? '',
      data: map['data'] ?? '',
      bookId: map['book_id'] ?? 0,
    );
  }

  factory Poem.fromSearchResult(Map<String, dynamic> args) {
    return Poem(
      id: int.tryParse(args['poem_id'] ?? '0') ?? 0,
      title: args['title'] ?? '',
      data: args['content'] ?? '',
      bookId: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'data': data,
      'book_id': bookId,
    };
  }

  Poem copyWith({
    int? id,
    int? bookId,
    String? title,
    String? data,
  }) => Poem(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    data: data ?? this.data,
  );

  String get cleanData {
    // Remove line numbers and clean up the text
    final lines = data.split('\n');
    final cleanedLines = lines.map((line) {
      // Remove line numbers (e.g., "1. " or "10. ")
      final cleaned = line.replaceAll(RegExp(r'^\d+\.\s*'), '');
      return cleaned.trim();
    }).where((line) => line.isNotEmpty).toList();
    
    return cleanedLines.join('\n');
  }

  @override
  List<Object> get props => [id, bookId, title, data];

  @override
  String toString() => 'Poem(id: $id, title: $title, bookId: $bookId)';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Poem &&
    other.id == id &&
    other.bookId == bookId;

  @override
  int get hashCode => id.hashCode ^ bookId.hashCode;
}