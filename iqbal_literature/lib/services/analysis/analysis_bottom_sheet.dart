import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';

class AnalysisBottomSheet extends StatefulWidget {
  final String poemTitle;
  final Future<String> analysisData;

  const AnalysisBottomSheet({
    super.key,
    required this.poemTitle,
    required this.analysisData,
  });

  static Future<void> show(BuildContext context, String poemTitle, Future<String> analysisData) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full screen
      enableDrag: true,
      useSafeArea: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, // Start at 70% of screen height
        minChildSize: 0.5, // Min 50%
        maxChildSize: 0.95, // Max 95%
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

  Widget _buildContent(String analysis) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Markdown(
              data: analysis,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                h1: Theme.of(context).textTheme.headlineMedium,
                h2: Theme.of(context).textTheme.titleLarge,
                h3: Theme.of(context).textTheme.titleMedium,
                listBullet: Theme.of(context).textTheme.bodyLarge,
                blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ),
        ),
      ),
    );
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
            'Powered by ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'DeepSeek',
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
    final oscillation = -exp(-damping * t) * cos(stiffness * t); // Changed e to exp
    return 1.0 + oscillation * (1.0 - t);
  }
}
