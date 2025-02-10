import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/historical_event.dart';
import '../../poems/controllers/poem_controller.dart';
import 'package:get/get.dart';

class IqbalTimelineWidget extends StatelessWidget {
  final List<HistoricalEvent> events;

  const IqbalTimelineWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEvents = events..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isFirst: index == 0,
          isLast: index == sortedEvents.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            height: 20,
            indicator: _buildIndicator(context, event),
          ),
          beforeLineStyle: LineStyle(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          endChild: _buildEventCard(context, event),
          startChild: _buildDateLabel(context, event),
        );
      },
    );
  }

  Widget _buildIndicator(BuildContext context, HistoricalEvent event) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: event.relatedPoemIds.isNotEmpty
          ? Icon(
              Icons.book,
              size: 12,
              color: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildEventCard(BuildContext context, HistoricalEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (event.relatedPoemIds.isNotEmpty) {
            _showRelatedPoems(context, event);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(event.description),
              if (event.relatedPoemIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap to view related poems',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateLabel(BuildContext context, HistoricalEvent event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '${event.date.year}',
        style: Theme.of(context).textTheme.titleSmall,
        textAlign: TextAlign.end,
      ),
    );
  }

  void _showRelatedPoems(BuildContext context, HistoricalEvent event) {
    final poemController = Get.find<PoemController>();
    final relatedPoems = poemController.poems
        .where((p) => event.relatedPoemIds.contains(p.id.toString()))
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: relatedPoems.length,
        itemBuilder: (context, index) {
          final poem = relatedPoems[index];
          return ListTile(
            title: Text(poem.title),
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/poem-detail', arguments: poem);
            },
          );
        },
      ),
    );
  }
}
