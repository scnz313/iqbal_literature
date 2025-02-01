import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Add this import for Clipboard
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../data/models/poem/poem.dart';

class PoemDetailView extends GetView<PoemController> {
  const PoemDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    late final Poem poem;
    
    try {
      if (args is Poem) {
        poem = args;
      } else if (args is Map<String, dynamic>) {
        poem = Poem.fromSearchResult(args);
      } else {
        return const Scaffold(
          body: Center(child: Text('Invalid poem data')),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      poem.title,
                      style: const TextStyle(
                        fontFamily: 'JameelNooriNastaleeq',
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                'From: ${controller.currentBookName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              position: PopupMenuPosition.under,
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    controller.sharePoem(poem);
                    break;
                  case 'copy':
                    final textToCopy = '${poem.title}\n\n${poem.cleanData}';
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Poem copied to clipboard')),
                    );
                    break;
                  case 'favorite':
                    controller.toggleFavorite(poem);
                    break;
                }
              },
              itemBuilder: (context) => [
                _buildMenuItem(
                  'share',
                  Icons.share,
                  'Share Poem',
                  context,
                ),
                _buildMenuItem(
                  'copy',
                  Icons.copy,
                  'Copy Text',
                  context,
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'favorite',
                  child: Obx(() => Row(
                    children: [
                      Icon(
                        controller.isFavorite(poem) 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        color: controller.isFavorite(poem) ? Colors.red : null,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        controller.isFavorite(poem) 
                            ? 'Remove from Favorites' 
                            : 'Add to Favorites',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Font Size',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MaterialButton(
                            minWidth: 0,
                            padding: const EdgeInsets.all(8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const CircleBorder(),
                            onPressed: controller.decreaseFontSize,
                            child: const Icon(Icons.remove, size: 20),
                          ),
                          const SizedBox(width: 4),
                          Obx(() => Text(
                            '${controller.fontSize.value.toInt()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )),
                          const SizedBox(width: 4),
                          MaterialButton(
                            minWidth: 0,
                            padding: const EdgeInsets.all(8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const CircleBorder(),
                            onPressed: controller.increaseFontSize,
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SafeArea(
                child: _buildPoemContent(context, poem),
              ),
              IconButton(
                icon: Obx(() => Icon(
                  controller.isFavorite(poem) 
                      ? Icons.favorite 
                      : Icons.favorite_border,
                )),
                onPressed: () => controller.toggleFavorite(poem),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading poem: $e');
      return const Scaffold(
        body: Center(child: Text('Error loading poem')),
      );
    }
  }

  Widget _buildPoemContent(BuildContext context, Poem poem) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => SelectableText(
                poem.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                  fontSize: controller.fontSize.value + 4,
                  height: 2.0,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              )),
              const SizedBox(height: 24),
              Obx(() => SelectableText(
                poem.cleanData,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                  fontSize: controller.fontSize.value,
                  height: 2.5,
                  letterSpacing: 0.5,
                ),
                textDirection: TextDirection.rtl,
              )),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPoemText(String text) {
    // Split into lines and clean up
    final lines = text.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Join with proper spacing
    return lines.join('\n\n');
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
    BuildContext context,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Color _getOverlayColor(bool isDark) {
    return (isDark ? Colors.black : Colors.white)
        .withAlpha((0.7 * 255).round());
  }
}

class StanzaWidget extends StatelessWidget {
  final String stanza;
  final int stanzaNumber;
  final int totalStanzas;

  const StanzaWidget({
    super.key,
    required this.stanza,
    required this.stanzaNumber,
    required this.totalStanzas,
  });

  @override
  Widget build(BuildContext context) {
    final lines = stanza.split('\n');
    final startLineNumber = _calculateStartLineNumber();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line number
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${startLineNumber + i}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Vertical line separator
                  Container(
                    width: 1,
                    height: 24,
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                  const SizedBox(width: 16),
                  // Poem line
                  Expanded(
                    child: SelectableText(
                      lines[i],
                      style: TextStyle(
                        fontFamily: 'JameelNooriNastaleeq',
                        fontSize: 24,
                        height: 2.2,
                        letterSpacing: 0.5,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black87
                            : Colors.white,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _calculateStartLineNumber() {
    if (stanzaNumber == 1) return 1;
    
    // Calculate based on previous stanzas
    int lineCount = 0;
    for (int i = 0; i < stanzaNumber - 1; i++) {
      lineCount += stanza.split('\n').length;
    }
    return lineCount + 1;
  }
}