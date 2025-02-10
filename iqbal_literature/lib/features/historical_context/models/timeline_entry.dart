import 'package:flutter/material.dart';

@immutable
class TimelineEntry {
  final String title;
  final String description;
  final DateTime date;
  final String? imageUrl;
  final String? wikipediaLink;
  final List<String>? relatedPoemIds;

  const TimelineEntry({
    required this.title,
    required this.description,
    required this.date,
    this.imageUrl,
    this.wikipediaLink,
    this.relatedPoemIds,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'imageUrl': imageUrl,
    'wikipediaLink': wikipediaLink,
    'relatedPoemIds': relatedPoemIds,
  };

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      imageUrl: json['imageUrl'],
      wikipediaLink: json['wikipediaLink'],
      relatedPoemIds: List<String>.from(json['relatedPoemIds'] ?? []),
    );
  }
}
