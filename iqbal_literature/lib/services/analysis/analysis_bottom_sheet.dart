import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';

// Add this class at the top, outside of any other class
// Helper class for content sections
class ContentSection {
  final String title;
  final String content;

  ContentSection({required this.title, required this.content});
}

class AnalysisBottomSheet extends StatefulWidget {
  final String poemTitle;
  final Future<String> analysisData;

  const AnalysisBottomSheet({
    super.key,
    required this.poemTitle,
    required this.analysisData,
  });

  static Future<void> show(
      BuildContext context, String poemTitle, Future<String> analysisData) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full screen
      enableDrag: true,
      useSafeArea: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8, // Start at 80% of screen height instead of 70%
        minChildSize: 0.6, // Min 60% instead of 50%
        maxChildSize: 0.95, // Max 95% (unchanged)
        builder: (_, controller) => AnalysisBottomSheet(
          poemTitle: poemTitle,
          analysisData: analysisData,
        ),
      ),
    );
  }

  @override
  State<AnalysisBottomSheet> createState() => _AnalysisBottomSheetState();
}

class _AnalysisBottomSheetState extends State<AnalysisBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _heightFactor = Tween<double>(
      begin: 0.0,
      end: 0.7, // 70% of screen height
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuint),
      ),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.7;
    final width = size.width;
    final isMobile = width < 600;
    final horizontalPadding = isMobile ? 0.0 : width * 0.1;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: maxHeight * _heightFactor.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Opacity(
                opacity: _opacity.value,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<String>(
                future: widget.analysisData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error!);
                  }
                  return _buildContent(snapshot.data!);
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      onVerticalDragEnd: (_) => Navigator.of(context).pop(),
      child: Container(
        height: 24,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.poemTitle,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: child,
            ),
            child: Row(
              children: [
                Text(
                  'Loading',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(width: 8),
                _buildLoadingDots(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLoadingLine('Analyzing poem structure'),
          _buildLoadingLine('Extracting themes'),
          _buildLoadingLine('Identifying metaphors'),
          _buildLoadingLine('Generating insights'),
          _buildLoadingLine('Finalizing analysis', showFin: true),
        ],
      ),
    );
  }

  Widget _buildLoadingLine(String text, {bool showFin = false}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.arrow_right, size: 20),
            const SizedBox(width: 8),
            Text(text),
            if (showFin) ...[
              const SizedBox(width: 8),
              Text(
                'fin.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return SizedBox(
      width: 24,
      child: TweenAnimationBuilder<int>(
        duration: const Duration(milliseconds: 1500),
        tween: IntTween(begin: 0, end: 3),
        builder: (context, value, child) {
          return Text(
            '.' * value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'Analysis failed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String content) {
    debugPrint(
        '🧩 Displaying analysis content: ${content.substring(0, min(content.length, 100))}...');

    // First check if content has markdown headers
    final bool hasMarkdownHeaders = content.contains('#');

    if (hasMarkdownHeaders) {
      // If it contains markdown headers, use Flutter Markdown
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(
          data: content,
          physics: const BouncingScrollPhysics(),
          styleSheet: MarkdownStyleSheet(
            h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            p: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    } else {
      // Otherwise, parse our own custom format (Section: content)
      final sections = _parseContentSections(content);

      return ListView.builder(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                  width: 0.5),
            ),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSectionIcon(section.title),
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatSectionTitle(section.title),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    section.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // Helper method to get an appropriate icon for each section
  IconData _getSectionIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('summary')) {
      return Icons.subject;
    } else if (lowerTitle.contains('theme')) {
      return Icons.lightbulb_outline;
    } else if (lowerTitle.contains('context') ||
        lowerTitle.contains('historical')) {
      return Icons.history_edu;
    } else if (lowerTitle.contains('analysis') ||
        lowerTitle.contains('literary')) {
      return Icons.analytics_outlined;
    } else {
      return Icons.article;
    }
  }

  // Helper method to format section title for display
  String _formatSectionTitle(String title) {
    // Remove the colon from the end
    String formatted =
        title.endsWith(':') ? title.substring(0, title.length - 1) : title;

    // Capitalize the first letter of each word
    formatted = formatted.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return word;
    }).join(' ');

    return formatted;
  }

  List<ContentSection> _parseContentSections(String content) {
    final List<ContentSection> sections = [];
    final lines = content.split('\n');

    String currentTitle = '';
    StringBuffer currentContent = StringBuffer();

    // Check if it's a simple string with no sections
    bool hasSections = false;
    for (final line in lines) {
      if (line.endsWith(':') && line.length < 50) {
        hasSections = true;
        break;
      }
    }

    // If no sections found, treat the whole thing as one analysis section
    if (!hasSections) {
      return [ContentSection(title: 'Analysis:', content: content)];
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // If line is empty and we're at the end, add current section
      if (line.isEmpty && i == lines.length - 1 && currentTitle.isNotEmpty) {
        sections.add(ContentSection(
          title: currentTitle,
          content: currentContent.toString().trim(),
        ));
        continue;
      }

      // Skip empty lines at the beginning
      if (line.isEmpty && currentTitle.isEmpty) {
        continue;
      }

      // Check if this line is a section title (ends with colon)
      // Make sure it's not too long to be a title
      if (line.endsWith(':') &&
          line.length < 50 &&
          (currentTitle.isEmpty ||
              currentContent.toString().trim().isNotEmpty)) {
        // Save previous section if we have one
        if (currentTitle.isNotEmpty) {
          sections.add(ContentSection(
            title: currentTitle,
            content: currentContent.toString().trim(),
          ));
          currentContent = StringBuffer();
        }

        currentTitle = line;
        continue;
      }

      // Otherwise, add to current content
      if (currentTitle.isNotEmpty) {
        if (currentContent.isNotEmpty) {
          currentContent.write('\n');
        }
        currentContent.write(line);
      } else if (line.isNotEmpty) {
        // If no title yet but line is not empty, create a default section
        currentTitle = 'Analysis:';
        currentContent.write(line);
      }

      // If we're at the end, add the final section
      if (i == lines.length - 1 && currentTitle.isNotEmpty) {
        sections.add(ContentSection(
          title: currentTitle,
          content: currentContent.toString().trim(),
        ));
      }
    }

    // If no sections were created, create a default one
    if (sections.isEmpty) {
      sections.add(ContentSection(
        title: 'Analysis:',
        content: content,
      ));
    }

    return sections;
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Analysis powered by ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Gemini AI',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class SpringCurve extends CurvedAnimation {
  SpringCurve({
    required double damping,
    required double stiffness,
  }) : super(
          parent: kAlwaysCompleteAnimation,
          curve: _SpringCurve(damping: damping, stiffness: stiffness),
        );
}

class _SpringCurve extends Curve {
  final double damping;
  final double stiffness;

  const _SpringCurve({
    required this.damping,
    required this.stiffness,
  });

  @override
  double transform(double t) {
    final oscillation =
        -exp(-damping * t) * cos(stiffness * t); // Changed e to exp
    return 1.0 + oscillation * (1.0 - t);
  }
}
