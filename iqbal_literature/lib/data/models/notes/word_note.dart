import 'package:hive/hive.dart';

part 'word_note.g.dart';

@HiveType(typeId: 4)
class WordNote extends HiveObject {
  @HiveField(0)
  final int poemId;

  @HiveField(1)
  final String word;

  @HiveField(2)
  final int position; // Position of the word in the poem text

  @HiveField(3)
  final String note;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String verse; // Store the verse this word belongs to for context

  WordNote({
    required this.poemId,
    required this.word,
    required this.position,
    required this.note,
    required this.createdAt,
    required this.verse,
  });

  Map<String, dynamic> toMap() {
    return {
      'poemId': poemId,
      'word': word,
      'position': position,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'verse': verse,
    };
  }

  factory WordNote.fromMap(Map<String, dynamic> map) {
    return WordNote(
      poemId: map['poemId'] as int,
      word: map['word'] as String,
      position: map['position'] as int,
      note: map['note'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      verse: map['verse'] as String,
    );
  }

  WordNote copyWith({
    int? poemId,
    String? word,
    int? position,
    String? note,
    DateTime? createdAt,
    String? verse,
  }) {
    return WordNote(
      poemId: poemId ?? this.poemId,
      word: word ?? this.word,
      position: position ?? this.position,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      verse: verse ?? this.verse,
    );
  }
}
