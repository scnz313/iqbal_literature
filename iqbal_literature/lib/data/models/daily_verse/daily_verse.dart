import 'package:cloud_firestore/cloud_firestore.dart';

class DailyVerse {
  final String id;
  final String originalText;
  final String translation;
  final String context;
  final String bookSource;
  final DateTime date;
  final String theme;
  final bool isUrdu;
  final Map<String, String>? aiInsights;

  DailyVerse({
    required this.id,
    required this.originalText,
    required this.translation,
    required this.context,
    required this.bookSource,
    required this.date,
    required this.theme,
    required this.isUrdu,
    this.aiInsights,
  });

  factory DailyVerse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyVerse(
      id: doc.id,
      originalText: data['originalText'] ?? '',
      translation: data['translation'] ?? '',
      context: data['context'] ?? '',
      bookSource: data['bookSource'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      theme: data['theme'] ?? '',
      isUrdu: data['isUrdu'] ?? false,
      aiInsights: data['aiInsights'] != null
          ? Map<String, String>.from(data['aiInsights'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalText': originalText,
      'translation': translation,
      'context': context,
      'bookSource': bookSource,
      'date': Timestamp.fromDate(date),
      'theme': theme,
      'isUrdu': isUrdu,
      'aiInsights': aiInsights,
    };
  }

  DailyVerse copyWith({
    String? id,
    String? originalText,
    String? translation,
    String? context,
    String? bookSource,
    DateTime? date,
    String? theme,
    bool? isUrdu,
    Map<String, String>? aiInsights,
  }) {
    return DailyVerse(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translation: translation ?? this.translation,
      context: context ?? this.context,
      bookSource: bookSource ?? this.bookSource,
      date: date ?? this.date,
      theme: theme ?? this.theme,
      isUrdu: isUrdu ?? this.isUrdu,
      aiInsights: aiInsights ?? this.aiInsights,
    );
  }
}
