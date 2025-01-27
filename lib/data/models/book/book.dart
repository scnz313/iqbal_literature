import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Book {
  final int id; // Ensure id is int type
  final String name;
  final String language;
  final String icon;
  final int orderBy;

  Book({
    required this.id,
    required this.name,
    required this.language,
    required this.icon,
    required this.orderBy,
  });

  factory Book.fromMap(Map<String, dynamic> data) {
    return Book(
      id: data['_id'] as int,
      icon: data['icon']?.toString() ?? '',
      language: data['language']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      orderBy: (data['order_by'] as num?)?.toInt() ?? 0,
    );
  }

  factory Book.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      debugPrint('Processing book data: $data');
      
      final id = data['_id'];
      if (id == null) {
        debugPrint('❌ Book _id is null in document ${doc.id}');
      }
      
      return Book(
        id: (id is int) ? id : (id as num).toInt(),
        name: data['name']?.toString() ?? '',
        language: data['language']?.toString() ?? '',
        icon: data['icon']?.toString() ?? '',
        orderBy: (data['order_by'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error parsing book ${doc.id}: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'language': language,
    'icon': icon,
    'orderBy': orderBy,
  };
}