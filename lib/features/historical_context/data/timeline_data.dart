import '../models/historical_event.dart';

final List<HistoricalEvent> timelineEvents = [
  HistoricalEvent(
    title: 'Birth of Allama Iqbal',
    description: 'Muhammad Iqbal was born in Sialkot, Punjab, British India.',
    date: DateTime(1877, 11, 9),
    location: 'Sialkot, Punjab',
    category: 'personal',
  ),
  HistoricalEvent(
    title: 'Publication of Bang-e-Dara',
    description: 'First collection of Urdu poetry published.',
    date: DateTime(1924),
    category: 'literary',
  ),
  // Add more historical events as needed
];
