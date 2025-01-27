import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../data/models/poem/poem.dart';

class PoemDetailView extends GetView<PoemController> {
  const PoemDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final poem = Get.arguments as Poem?;
    
    if (poem == null) {
      return const Scaffold(
        body: Center(child: Text('Poem not found')),
      );
    }

    // Split poem into stanzas (double newlines indicate stanza breaks)
    final stanzas = poem.data.split('\n\n');

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
          Obx(() => IconButton(
            icon: Icon(
              controller.isFavorite(poem) ? Icons.favorite : Icons.favorite_border,
              color: controller.isFavorite(poem) ? Colors.red : null,
            ),
            onPressed: () => controller.toggleFavorite(poem),
          )),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => controller.sharePoem(poem),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int stanzaIndex = 0; stanzaIndex < stanzas.length; stanzaIndex++) ...[
                StanzaWidget(
                  stanza: stanzas[stanzaIndex],
                  stanzaNumber: stanzaIndex + 1,
                  totalStanzas: stanzas.length,
                ),
                if (stanzaIndex < stanzas.length - 1)
                  const SizedBox(height: 24), // Space between stanzas
              ],
            ],
          ),
        ),
      ),
    );
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