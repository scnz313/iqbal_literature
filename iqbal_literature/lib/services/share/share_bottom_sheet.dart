import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/poems/models/poem.dart';
import 'share_service.dart';

class ShareBottomSheet extends StatelessWidget {
  final Poem poem;
  const ShareBottomSheet({super.key, required this.poem});

  static void show(BuildContext context, Poem poem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.4,
        builder: (_, controller) => _ShareBottomSheetContent(poem: poem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ShareBottomSheetContent(poem: poem);
  }
}

class _ShareBottomSheetContent extends StatelessWidget {
  final Poem poem;

  const _ShareBottomSheetContent({required this.poem});

  Widget _buildPreviewWidget() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight * 0.6,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                poem.title,
                style: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                  fontSize: 24,
                  height: 2,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    poem.cleanData,
                    style: const TextStyle(
                      fontFamily: 'JameelNooriNastaleeq',
                      fontSize: 18,
                      height: 2,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Add ScrollView to handle overflow
          child: Column(
            mainAxisSize: MainAxisSize.min, // Keep this to minimize height
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Share Poem',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildShareOption(
                context: context,
                icon: Icons.text_fields,
                title: 'Share as Text',
                subtitle: 'Share poem text to other apps',
                onTap: () async {
                  try {
                    await ShareService.shareAsText(poem.title, poem.cleanData);
                    Navigator.pop(context);
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Failed to share text: $e',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
              _buildShareOption(
                context: context,
                icon: Icons.image,
                title: 'Share as Image',
                subtitle: 'Create and share a beautiful image',
                onTap: () async {
                  try {
                    final imageWidget = Material(
                      color: Colors.white,
                      child: _buildPreviewWidget(),
                    );

                    if (context.mounted) {
                      await ShareService.shareAsImage(
                        context,
                        imageWidget,
                        'poem_${poem.id}',
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      Get.snackbar(
                        'Error',
                        'Failed to share image: $e',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
