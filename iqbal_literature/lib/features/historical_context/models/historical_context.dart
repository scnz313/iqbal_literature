class HistoricalContext {
  final String year;
  final String historicalContext;
  final String significance;
  final String? culturalImportance;
  final String? religiousThemes;
  final String? politicalMessages;
  final String? imagery;
  final String? metaphor;
  final String? symbolism;
  final String? theme;

  HistoricalContext({
    required this.year,
    required this.historicalContext,
    required this.significance,
    this.culturalImportance,
    this.religiousThemes,
    this.politicalMessages,
    this.imagery,
    this.metaphor,
    this.symbolism,
    this.theme,
  });

  factory HistoricalContext.fromMap(Map<String, dynamic> map) {
    return HistoricalContext(
      year: map['year']?.toString() ?? 'Unknown',
      historicalContext: map['historicalContext']?.toString() ?? 'Not available',
      significance: map['significance']?.toString() ?? 'Not available',
      culturalImportance: map['culturalImportance']?.toString(),
      religiousThemes: map['religiousThemes']?.toString(),
      politicalMessages: map['politicalMessages']?.toString(),
      imagery: map['imagery']?.toString(),
      metaphor: map['metaphor']?.toString(),
      symbolism: map['symbolism']?.toString(),
      theme: map['theme']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'year': year,
    'historicalContext': historicalContext,
    'significance': significance,
    'culturalImportance': culturalImportance,
    'religiousThemes': religiousThemes,
    'politicalMessages': politicalMessages,
    'imagery': imagery,
    'metaphor': metaphor,
    'symbolism': symbolism,
    'theme': theme,
  };

  factory HistoricalContext.empty() => HistoricalContext(
    year: 'Unknown',
    historicalContext: 'Not available',
    significance: 'Not available',
    culturalImportance: null,
    religiousThemes: null,
    politicalMessages: null,
    imagery: null,
    metaphor: null,
    symbolism: null,
    theme: null,
  );
}
