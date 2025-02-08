import 'package:flutter/material.dart';

@immutable
class HistoricalEvent {
  final String title;
  final String description;
  final DateTime date;
  final String? location;
  final String? wikipediaUrl;
  final String? imageUrl;
  final List<String> relatedPoemIds;
  final String? category;

  const HistoricalEvent({
    required this.title,
    required this.description,
    required this.date,
    this.location,
    this.wikipediaUrl,
    this.imageUrl,
    this.relatedPoemIds = const [],
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'location': location,
    'wikipediaUrl': wikipediaUrl,
    'imageUrl': imageUrl,
    'relatedPoemIds': relatedPoemIds,
    'category': category,
  };

  factory HistoricalEvent.fromJson(Map<String, dynamic> json) {
    return HistoricalEvent(
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      wikipediaUrl: json['wikipediaUrl'],
      imageUrl: json['imageUrl'],
      relatedPoemIds: List<String>.from(json['relatedPoemIds'] ?? []),
      category: json['category'],
    );
  }
}