import 'package:flutter/material.dart';
import '../models/historical_event.dart';
import './iqbal_timeline_widget.dart';
import '../../../core/constants/timeline_constants.dart';

class HistoricalContextWidget extends StatelessWidget {
  final List<HistoricalEvent> events;
  
  const HistoricalContextWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historical Context',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore the historical events and context surrounding Iqbal\'s works',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: IqbalTimelineWidget(events: events),
        ),
      ],
    );
  }
}
