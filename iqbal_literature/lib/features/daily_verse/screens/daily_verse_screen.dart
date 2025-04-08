import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../controllers/daily_verse_controller.dart';

class DailyVerseScreen extends GetView<DailyVerseController> {
  const DailyVerseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value && controller.currentVerse.value == null) {
          return _buildLoadingState(theme);
        }
        
        if (controller.error.value.isNotEmpty && controller.currentVerse.value == null) {
          return _buildErrorState(theme);
        }
        
        if (controller.currentVerse.value == null) {
          return _buildEmptyState(theme);
        }
        
        // Main content
        return CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Daily Wisdom',
                  style: TextStyle(
                    fontFamily: 'JameelNooriNastaleeq',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background pattern or image
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDarkMode 
                            ? [
                                theme.colorScheme.background.withOpacity(0.9),
                                theme.colorScheme.secondary.withOpacity(0.2),
                              ]
                            : [
                                theme.colorScheme.primaryContainer.withOpacity(0.3),
                                theme.colorScheme.primary.withOpacity(0.1),
                              ],
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/backgrounds/pattern_light.png'),
                          fit: BoxFit.cover,
                          opacity: 0.1,
                        ),
                      ),
                    ),
                    // Overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              theme.colorScheme.surface.withOpacity(0.8),
                              theme.colorScheme.surface.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share this verse',
                  onPressed: _shareVerse,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Get a new verse',
                  onPressed: controller.refreshVerse,
                ),
              ],
            ),
            
            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source info banner
                    if (controller.generationSource.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  controller.generationSource.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // The actual verse card
                    _buildVerseCard(theme),
                    const SizedBox(height: 24),
                    
                    // Insights section
                    _buildInsightsSection(theme),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Preparing your daily wisdom...',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'We couldn\'t load your daily wisdom',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              controller.error.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.loadDailyVerse,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Daily Wisdom Available',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to generate one for you',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshVerse,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate Verse'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(ThemeData theme) {
    final verse = controller.currentVerse.value!;
    final brightness = theme.brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return GestureDetector(
      onLongPress: () {
        // Copy verse to clipboard on long press
        final text = '${verse.originalText}\n\n${verse.translation}';
        Clipboard.setData(ClipboardData(text: text));
        
        // Show feedback
        final snackBar = SnackBar(
          content: const Text('Verse copied to clipboard'),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {},
          ),
        );
        ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          color: isDarkMode 
              ? theme.colorScheme.surface.withOpacity(0.8) 
              : theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Theme badge
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verse.theme,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Original verse text (Urdu/Persian)
                Text(
                  verse.originalText,
                  style: TextStyle(
                    fontFamily: 'JameelNooriNastaleeq',
                    fontSize: 30,
                    height: 1.8,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                
                const SizedBox(height: 20),
                
                // English translation
                Text(
                  verse.translation,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                // Source information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Source:',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        verse.bookSource,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Context info if available
                if (verse.context.isNotEmpty && verse.context != 'null')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Context:',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            verse.context,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI-Powered Insights',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (controller.currentVerse.value?.aiInsights == null &&
                !controller.isGeneratingInsights.value)
              TextButton.icon(
                onPressed: () => controller.generateInsights(),
                icon: const Icon(Icons.psychology),
                label: const Text('Generate'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isGeneratingInsights.value) {
            return _buildInsightsLoadingState(theme);
          }
          
          final insights = controller.currentVerse.value?.aiInsights;
          if (insights == null) {
            return _buildNoInsightsState(theme);
          }
          
          return _buildInsightsContent(theme, insights);
        }),
      ],
    );
  }

  Widget _buildInsightsLoadingState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating insights...',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our AI is analyzing this verse to provide deeper context and meaning',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoInsightsState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No insights available',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Generate" to get AI-powered insights about this verse',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.generateInsights(),
            icon: const Icon(Icons.psychology),
            label: const Text('Generate Insights'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(ThemeData theme, Map<String, String> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightCard(
          theme,
          'Explanation',
          insights['explanation'],
          Icons.subject,
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          theme,
          'Key Themes',
          insights['themes'],
          Icons.category,
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          theme,
          'Historical Context',
          insights['context'],
          Icons.history_edu,
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          theme,
          'Life Lessons',
          insights['wisdom'],
          Icons.lightbulb,
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    ThemeData theme,
    String title,
    String? content,
    IconData icon,
  ) {
    if (content == null || content.isEmpty || content == 'null') {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  void _shareVerse() {
    if (controller.currentVerse.value != null) {
      final verse = controller.currentVerse.value!;
      final shareText = '''
${verse.originalText}

${verse.translation}

From: ${verse.bookSource}
Theme: ${verse.theme}
${verse.aiInsights != null ? '\n${verse.aiInsights!['explanation'] ?? ''}' : ''}

Shared from Iqbal Literature app
''';
      
      Share.share(shareText);
    }
  }
}
