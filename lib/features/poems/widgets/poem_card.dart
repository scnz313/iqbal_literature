import 'package:flutter/material.dart';
import '../../../data/models/poem/poem.dart';
import '../controllers/poem_controller.dart';
import 'package:get/get.dart';

class PoemCard extends StatelessWidget {
  final String title;
  final Poem poem;

  const PoemCard({
    super.key,
    required this.title,
    required this.poem,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        
        return Card(
          elevation: 4.0,
          margin: EdgeInsets.all(isWideScreen ? 12.0 : 8.0),
          child: Padding(
            padding: EdgeInsets.all(isWideScreen ? 20.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: isWideScreen ? 24.0 : 20.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                FutureBuilder<String>(
                  future: Get.find<PoemController>().getBookName(poem.bookId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return Text(
                      snapshot.data!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: isWideScreen ? 16.0 : 14.0,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
