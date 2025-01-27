import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../data/models/poem/poem.dart';

class PoemsScreen extends GetView<PoemController> {
  const PoemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.currentBookName.value,
          style: const TextStyle(
            fontFamily: 'JameelNooriNastaleeq',
            fontSize: 22,
          ),
          textDirection: TextDirection.rtl,
        )),
        actions: [
          // Add debug button in debug mode
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                final args = Get.arguments;
                debugPrint('Current arguments: $args');
                debugPrint('Current book name: ${controller.currentBookName.value}');
                debugPrint('Loaded poems: ${controller.poems.length}');
                if (controller.poems.isNotEmpty) {
                  debugPrint('First poem: ${controller.poems.first.toMap()}');
                }
              },
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.error.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.loadPoemsByBookId(
                    Get.arguments['book_id']
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.poems.isEmpty) {
          return Center(
            child: Text(
              'No poems found for this book',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.poems.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final poem = controller.poems[index];
            return PoemCard(poem: poem);
          },
        );
      }),
    );
  }
}

class PoemCard extends StatelessWidget {
  final Poem poem;

  const PoemCard({
    super.key,
    required this.poem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Get.find<PoemController>().onPoemTap(poem),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_stories,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      poem.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'JameelNooriNastaleeq',
                        fontSize: 20,
                        height: 1.8,
                        letterSpacing: 0.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    if (poem.data.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        poem.data.split('\n').first,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'JameelNooriNastaleeq',
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}