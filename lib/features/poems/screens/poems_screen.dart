import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../data/models/poem/poem.dart';

class PoemsScreen extends GetView<PoemController> {
  const PoemsScreen({super.key});

  Widget _buildErrorWidget(BuildContext context, String error) {
    final args = Get.arguments;
    final bookId = args?['book_id'];
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (bookId != null)
            ElevatedButton.icon(
              onPressed: () => controller.loadPoemsByBookId(bookId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  String _getTitle() {
    final args = Get.arguments;
    final viewType = args?['view_type'];
    final bookName = args?['book_name'];

    if (viewType == 'book_specific' && bookName != null) {
      return bookName;
    }
    return 'All Poems';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('all_poems'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.error.value.isNotEmpty) {
          return _buildErrorWidget(context, controller.error.value);
        }

        if (controller.poems.isEmpty) {
          return Center(
            child: Text(
              'No poems found',
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
                child: Text(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}