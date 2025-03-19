import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Book {
  final int id; // Ensure id is int type
  final String name;
  final String language;
  final String icon;
  final int orderBy;
  final String? timePeriod; // Add this field

  Book({
    required this.id,
    required this.name,
    required this.language,
    required this.icon,
    required this.orderBy,
    this.timePeriod, // Add this parameter
  });

  factory Book.fromMap(Map<String, dynamic> data) {
    // Make sure we have a valid id
    final dynamic rawId = data['_id'] ?? data['id'];
    if (rawId == null) {
      throw ArgumentError('Book id cannot be null');
    }

    // Convert id to int safely
    final int id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId is num) {
      id = rawId.toInt();
    } else if (rawId is String) {
      id = int.parse(rawId);
    } else {
      throw ArgumentError('Invalid book id type: ${rawId.runtimeType}');
    }

    return Book(
      id: id,
      icon: data['icon']?.toString() ?? '',
      language: data['language']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      orderBy: (data['order_by'] as num?)?.toInt() ?? 0,
      timePeriod: data['time_period']?.toString(), // Add this field
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
        timePeriod: data['time_period']?.toString(), // Add this field
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
        'time_period': timePeriod, // Add this field
      };
}
