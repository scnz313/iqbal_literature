class TimelineEvent {
  final String year;
  final String title;
  final String description;
  final String significance;

  TimelineEvent({
    required this.year,
    required this.title,
    required this.description,
    required this.significance,
  });

  factory TimelineEvent.fromMap(Map<String, dynamic> map) {
    return TimelineEvent(
      year: map['year']?.toString() ?? 'Unknown',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      significance: map['significance']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'year': year,
    'title': title,
    'description': description,
    'significance': significance,
  };

  factory TimelineEvent.empty() => TimelineEvent(
    year: 'Unknown',
    title: 'Not available',
    description: 'Not available',
    significance: 'Not available',
  );
}
