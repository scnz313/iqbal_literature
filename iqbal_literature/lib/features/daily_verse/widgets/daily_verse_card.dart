import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daily_verse_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DailyVerseCard extends GetView<DailyVerseController> {
  const DailyVerseCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingCard(context);
      }

      if (controller.error.isNotEmpty) {
        return _buildErrorCard(context);
      }

      final verse = controller.currentVerse.value;
      if (verse == null) {
        return _buildEmptyCard(context);
      }

      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Wisdom',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: controller.shareVerse,
                    tooltip: 'Share',
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Original Text
              Text(
                verse.originalText,
                style: textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
                textAlign: verse.isUrdu ? TextAlign.right : TextAlign.left,
              ),
              SizedBox(height: 16.h),

              // Divider
              Divider(
                color: colorScheme.primary.withOpacity(0.2),
                thickness: 1,
                height: 24.h,
              ),

              // Translation
              Text(
                verse.translation,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 12.h),

              // Source and Theme
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    verse.bookSource,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      verse.theme,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // AI Insights
              if (controller.isGeneratingInsights.value)
                _buildInsightsLoadingIndicator()
              else if (verse.aiInsights != null)
                _buildInsightsSection(verse.aiInsights!, colorScheme, textTheme)
              else
                _buildGenerateInsightsButton(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInsightsLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8.w),
          Text(
            'Generating insights...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(
    Map<String, String> insights,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        if (insights['explanation'] != null) ...[
          _buildInsightItem(
            'Explanation',
            insights['explanation']!,
            colorScheme,
            textTheme,
          ),
          SizedBox(height: 8.h),
        ],
        if (insights['themes'] != null) ...[
          _buildInsightItem(
            'Key Themes',
            insights['themes']!,
            colorScheme,
            textTheme,
          ),
          SizedBox(height: 8.h),
        ],
        if (insights['context'] != null) ...[
          _buildInsightItem(
            'Historical Context',
            insights['context']!,
            colorScheme,
            textTheme,
          ),
          SizedBox(height: 8.h),
        ],
        if (insights['wisdom'] != null)
          _buildInsightItem(
            'Practical Wisdom',
            insights['wisdom']!,
            colorScheme,
            textTheme,
          ),
      ],
    );
  }

  Widget _buildInsightItem(
    String title,
    String content,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            content,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateInsightsButton() {
    return Center(
      child: TextButton.icon(
        onPressed: controller.generateInsights,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate AI Insights'),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 32.w),
            SizedBox(height: 8.h),
            Text(
              controller.error.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: controller.loadDailyVerse,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: colorScheme.primary.withOpacity(0.5),
              size: 32.w,
            ),
            SizedBox(height: 8.h),
            Text(
              'No verse available',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
