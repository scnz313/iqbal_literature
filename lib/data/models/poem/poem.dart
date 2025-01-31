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
  final List<String>? lines;

  const Poem({
    required this.id,
    required this.numericId,
    required this.title,
    required this.data,
    required this.bookId,
    this.lines,
  });

  factory Poem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Ensure book_id is properly converted to int
    final bookId = data['book_id'];
    if (bookId == null) {
      throw Exception('book_id is required');
    }
    
    debugPrint('Converting Firestore doc ${doc.id}:');
    debugPrint('Raw book_id: $bookId (${bookId.runtimeType})');

    return Poem(
      id: doc.id,
      numericId: data['_id'] ?? 0,
      title: data['title'] ?? '',
      data: data['data'] ?? '',
      bookId: bookId is int ? bookId : int.parse(bookId.toString()),
      lines: data['lines'] != null ? List<String>.from(data['lines']) : null,
    );
  }

  factory Poem.fromMap(Map<String, dynamic> map) {
    return Poem(
      id: map['_id']?.toString() ?? '',
      numericId: map['_id'] ?? 0,
      title: map['title'] ?? '',
      data: map['data'] ?? '',
      bookId: map['book_id'] ?? 0,
      lines: map['lines'] != null 
          ? List<String>.from(map['lines']) 
          : null,
    );
  }

  factory Poem.fromSearchResult(Map<String, dynamic> args) {
    return Poem(
      id: args['poem_id'] ?? '0',
      numericId: int.tryParse(args['poem_id'] ?? '0') ?? 0,
      title: args['title'] ?? '',
      data: args['content'] ?? '',
      bookId: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': numericId,
      'title': title,
      'data': data,
      'book_id': bookId,
      if (lines != null) 'lines': lines,
    };
  }

  Poem copyWith({
    String? id,
    int? numericId,
    int? bookId,
    String? title,
    String? data,
    List<String>? lines,
  }) => Poem(
    id: id ?? this.id,
    numericId: numericId ?? this.numericId,
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    data: data ?? this.data,
    lines: lines ?? this.lines,
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
  List<Object> get props => [id, numericId, bookId, title, data, lines ?? []];

  @override
  String toString() => 'Poem(id: $id, numericId: $numericId, title: $title, bookId: $bookId)';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Poem &&
    other.id == id &&
    other.bookId == bookId;

  @override
  int get hashCode => id.hashCode ^ bookId.hashCode;
}