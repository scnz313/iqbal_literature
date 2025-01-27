import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import '../line/line.dart';

@immutable
class Poem extends Equatable {
  final String id;  // Changed to String to match Firestore document ID
  final int numericId;  // Added for _id
  final String title;
  final String data;
  final int bookId;
  final List<Line>? lines;

  const Poem({
    required this.id,
    required this.numericId,
    required this.title,
    required this.data,
    required this.bookId,
    this.lines,
  });

  factory Poem.fromMap(Map<String, dynamic> data) {
    return Poem(
      id: data['id']?.toString() ?? '',
      numericId: data['_id'] as int? ?? 0,
      title: data['title'] as String? ?? '',
      data: data['data'] as String? ?? '',
      bookId: data['book_id'] as int? ?? 0,
      lines: const [], // Lines will be loaded separately
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    '_id': numericId,
    'title': title,
    'data': data,
    'book_id': bookId,
    'lines': lines?.map((line) => line.toMap()).toList(),
  };

  factory Poem.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      debugPrint('Converting Firestore data for ${doc.id}: $data');

      // Parse book_id with detailed logging
      final rawBookId = data['book_id'];
      debugPrint('Raw book_id: $rawBookId (${rawBookId.runtimeType})');
      
      int bookId;
      if (rawBookId is int) {
        bookId = rawBookId;
      } else if (rawBookId is String) {
        bookId = int.tryParse(rawBookId) ?? 0;
      } else if (rawBookId is num) {
        bookId = rawBookId.toInt();
      } else {
        debugPrint('⚠️ Unexpected book_id type: ${rawBookId.runtimeType}');
        bookId = 0;
      }
      
      debugPrint('Parsed book_id: $bookId');

      return Poem(
        id: doc.id,
        numericId: (data['_id'] as num?)?.toInt() ?? 0,
        title: data['title']?.toString() ?? '',
        data: data['data']?.toString() ?? '',
        bookId: bookId,
      );
    } catch (e, stack) {
      debugPrint('❌ Error parsing poem ${doc.id}: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  Poem copyWith({
    String? id,
    int? numericId,
    int? bookId,
    String? title,
    String? data,
    List<Line>? lines,
  }) => Poem(
    id: id ?? this.id,
    numericId: numericId ?? this.numericId,
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    data: data ?? this.data,
    lines: lines ?? this.lines,
  );

  @override
  List<Object> get props => [id, numericId, bookId, title, data, lines ?? []];

  @override
  String toString() => 'Poem(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Poem &&
    other.id == id &&
    other.bookId == bookId;

  @override
  int get hashCode => id.hashCode ^ bookId.hashCode;
}