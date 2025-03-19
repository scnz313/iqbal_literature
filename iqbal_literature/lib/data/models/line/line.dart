import 'package:cloud_firestore/cloud_firestore.dart';

class Line {
  final int id;
  final int poemId;
  final String lineText;
  final int orderBy;

  Line({
    required this.id,
    required this.poemId,
    required this.lineText,
    required this.orderBy,
  });

  factory Line.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Line(
      id: data['_id'] as int,
      poemId: data['poem_id'] as int,
      lineText: data['line_text'] as String,
      orderBy: data['order_by'] as int,
    );
  }

  factory Line.fromMap(Map<String, dynamic> map) {
    return Line(
      id: map['_id'] as int,
      poemId: map['poem_id'] as int,
      lineText: map['line_text'] as String,
      orderBy: map['order_by'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        '_id': id,
        'poem_id': poemId,
        'line_text': lineText,
        'order_by': orderBy,
      };
}
