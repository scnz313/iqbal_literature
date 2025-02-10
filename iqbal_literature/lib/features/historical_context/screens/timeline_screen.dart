import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/historical_context_controller.dart';

class TimelineScreen extends GetView<HistoricalContextController> {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>;
      controller.loadTimelineData(
        args['book_name'] as String,
        timePeriod: args['time_period'] as String?,
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Historical Timeline: ${Get.arguments?['book_name'] ?? 'Loading...'}'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = controller.timelineEvents;
        
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No timeline events available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadTimelineData(
                    Get.arguments?['book_name'] ?? '',
                    timePeriod: Get.arguments?['time_period'],
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return TimelineEventCard(
              year: event.year?.toString() ?? 'Unknown',
              title: event.title ?? 'Untitled Event',
              description: event.description ?? 'No description available',
              significance: event.significance ?? 'No significance provided',
            );
          },
        );
      }),
    );
  }
}

class TimelineEventCard extends StatelessWidget {
  final String year;
  final String title;
  final String description;
  final String significance;

  const TimelineEventCard({
    super.key,
    required this.year,
    required this.title,
    required this.description,
    required this.significance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(year)),
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const Divider(),
                Text(
                  'Historical Significance:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(significance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
