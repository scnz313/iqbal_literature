import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../features/poems/models/poem.dart';
import '../../../services/api/openrouter_service.dart';

class PoemsScreen extends StatefulWidget {
  const PoemsScreen({super.key});

  @override
  State<PoemsScreen> createState() => _PoemsScreenState();
}

class _PoemsScreenState extends State<PoemsScreen> {
  final PoemController controller = Get.find<PoemController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (args == null) {
        debugPrint('📚 Loading all poems (direct access)');
        controller.loadAllPoems();
      } else {
        final bookId = args['book_id'];
        final viewType = args['view_type'];
        
        if (bookId != null && viewType == 'book_specific') {
          debugPrint('📚 Loading poems for book: $bookId');
          controller.loadPoemsByBookId(bookId);
        } else {
          debugPrint('📚 Loading all poems (fallback)');
          controller.loadAllPoems();
        }
      }
    });
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    final args = Get.arguments as Map<String, dynamic>?;
    final bookId = args?['book_id'];
    debugPrint('Error widget args: $args');
    
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
    final args = Get.arguments as Map<String, dynamic>?;
    final viewType = args?['view_type'];
    final bookName = args?['book_name'];

    if (viewType == 'book_specific' && bookName != null) {
      return bookName;
    }
    return 'all_poems'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
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
        onLongPress: () => _showOptions(context),
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

  void _showOptions(BuildContext context) {
    debugPrint('Showing options for poem: ${poem.title}');
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history_edu),
              title: const Text('Historical Context'),
              onTap: () {
                Navigator.pop(context);
                _showHistoricalContext(context);
              },
            ),
            ListTile(
              leading: Obx(() {
                final isFav = Get.find<PoemController>().isFavorite(poem);
                return Icon(
                  isFav ? Icons.favorite : Icons.favorite_outline,
                  color: isFav ? Colors.red : null,
                );
              }),
              title: Obx(() {
                final isFav = Get.find<PoemController>().isFavorite(poem);
                return Text(isFav ? 'Remove from Favorites' : 'Add to Favorites');
              }),
              onTap: () {
                Navigator.pop(context);
                Get.find<PoemController>().toggleFavorite(poem);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoricalContext(BuildContext context) {
    debugPrint('📖 Requesting historical context for: ${poem.title}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Historical Context',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<Map<String, String>>(
                  future: OpenRouterService.getHistoricalContext(poem.title, poem.cleanData),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Analyzing historical context...'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: Could not retrieve historical context',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data ?? {
                      'year': 'Unknown',
                      'historicalContext': 'No historical context available',
                      'significance': 'No significance data available'
                    };

                    return ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Year: ${data['year']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Historical Context:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['historicalContext'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Significance:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['significance'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}