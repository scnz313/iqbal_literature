import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../features/poems/models/poem.dart';
import '../../../widgets/analysis/word_analysis_sheet.dart';
import '../widgets/poem_stanza_widget.dart';
import '../widgets/poem_notes_sheet.dart';

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
          title: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          poem.title,
                          style: TextStyle(
                            fontFamily: 'JameelNooriNastaleeq',
                            fontSize: controller.fontSize.value +
                                8, // reactive update
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
              )),
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
                  case 'analyze':
                    controller.showPoemAnalysis(poem.cleanData);
                    break;
                  case 'favorite':
                    controller.toggleFavorite(poem);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Obx(() => Icon(
                            controller.isFavorite(poem)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                controller.isFavorite(poem) ? Colors.red : null,
                            size: 20,
                          )),
                      const SizedBox(width: 12),
                      Obx(() => Text(
                            controller.isFavorite(poem)
                                ? 'Remove from Favorites'
                                : 'Add to Favorites',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'analyze',
                  child: Row(
                    children: [
                      Obx(() => controller.isAnalyzing.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.analytics, size: 20)),
                      const SizedBox(width: 12),
                      Text(
                        'Analyze Poem',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
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
                  enabled: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
        body: Obx(() => SingleChildScrollView(
              child: SafeArea(
                child: _buildPoemContent(
                    context, poem), // now rebuilds on fontSize update
              ),
            )),
        floatingActionButton: Obx(() => controller.isShowingNotes.value
            ? const SizedBox.shrink() // Hide FAB when notes are already showing
            : FloatingActionButton(
                onPressed: () {
                  try {
                    final poem = Get.arguments is Poem
                        ? Get.arguments as Poem
                        : Get.arguments is Map<String, dynamic>
                            ? Poem.fromSearchResult(Get.arguments)
                            : null;

                    if (poem != null) {
                      _showNotesBottomSheet(context, poem);
                    }
                  } catch (e) {
                    debugPrint('Error opening notes: $e');
                  }
                },
                child: const Icon(Icons.notes),
                tooltip: 'View Notes',
              ) as Widget),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    } catch (e) {
      debugPrint('Error loading poem: $e');
      return const Scaffold(
        body: Center(child: Text('Error loading poem')),
      );
    }
  }

  Widget _buildPoemContent(BuildContext context, Poem poem) {
    final stanzas = _splitIntoStanzas(poem.cleanData);
    var lineNumber = 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              poem.title,
              style: TextStyle(
                fontFamily: 'JameelNooriNastaleeq',
                fontSize: controller.fontSize.value + 8,
                height: 2.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),

          const SizedBox(height: 32),

          // Analysis Results Section
          Obx(() {
            if (controller.showAnalysis.value) {
              return _buildAnalysisSection(context, {
                'summary': controller.poemAnalysis.value,
                'themes': '',
                'context': '',
                'analysis': ''
              });
            }
            return const SizedBox.shrink();
          }),

          // Stanzas with line numbers
          for (final stanza in stanzas)
            Builder(builder: (context) {
              final currentLineNumber = lineNumber;
              lineNumber += stanza.length;
              return PoemStanzaWidget(
                verses: stanza,
                startLineNumber: currentLineNumber,
                fontSize: controller.fontSize.value,
                onWordTap: (word) => _showWordAnalysis(context, word),
                poemId: poem.id,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(
      BuildContext context, Map<String, String> analysis) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisHeader('Summary', analysis['summary'] ?? ''),
          const Divider(height: 32),
          _buildAnalysisHeader('Themes', analysis['themes'] ?? ''),
          const Divider(height: 32),
          _buildAnalysisHeader('Historical Context', analysis['context'] ?? ''),
          const Divider(height: 32),
          _buildAnalysisHeader('Analysis', analysis['analysis'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(content),
      ],
    );
  }

  void _showWordAnalysis(BuildContext context, String word) async {
    try {
      final analysis = await controller.analyzeWord(word);
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          enableDrag: true,
          useSafeArea: true,
          isDismissible: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (_, scrollController) =>
                WordAnalysisSheet(analysis: analysis),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar(
          'Error',
          'Failed to analyze word. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  List<List<String>> _splitIntoStanzas(String text) {
    return text
        .split('\n\n')
        .map((stanza) =>
            stanza.split('\n').where((line) => line.trim().isNotEmpty).toList())
        .where((stanza) => stanza.isNotEmpty)
        .toList();
  }

  String _formatPoemText(String text) {
    // Split into lines and clean up
    final lines = text
        .split('\n')
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

  void _showNotesBottomSheet(BuildContext context, Poem poem) {
    // Check if already showing notes to prevent duplicate sheets
    if (controller.isShowingNotes.value) {
      debugPrint('📝 Already showing notes sheet, ignoring duplicate request');
      return;
    }

    // Set notes as visible
    controller.toggleNotesVisibility(true);

    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    debugPrint('Opening notes for poem: ${poem.id} from consolidated method');

    // Show notes bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notes for "${poem.title}"',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.toggleNotesVisibility(false);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content - Direct PoemNotesSheet without wrapping
            Expanded(
              child: PoemNotesSheet(
                poemId: poem.id,
                poemTitle: poem.title,
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Always reset state when sheet is closed
      controller.toggleNotesVisibility(false);
    });
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
