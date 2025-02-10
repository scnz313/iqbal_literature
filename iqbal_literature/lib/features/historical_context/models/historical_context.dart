class HistoricalContext {
  final String year;
  final String historicalContext;
  final String significance;

  HistoricalContext({
    required this.year,
    required this.historicalContext,
    required this.significance,
  });

  factory HistoricalContext.fromMap(Map<String, dynamic> map) {
    return HistoricalContext(
      year: map['year']?.toString() ?? 'Unknown',
      historicalContext: map['historicalContext']?.toString() ?? 'Not available',
      significance: map['significance']?.toString() ?? 'Not available',
    );
  }

  Map<String, dynamic> toMap() => {
    'year': year,
    'historicalContext': historicalContext,
    'significance': significance,
  };

  factory HistoricalContext.empty() => HistoricalContext(
    year: 'Unknown',
    historicalContext: 'Not available',
    significance: 'Not available',
  );
}
