import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: GestureDetector(
        onTap: controller.skipAndNavigate,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Background pattern - subtle geometric shapes
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: BackgroundPatternPainter(colorScheme.primary),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Obx(() => AnimatedOpacity(
                    opacity: controller.contentVisible.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: isLandscape
                            ? _buildLandscapeLayout(
                                context, colorScheme, textTheme)
                            : _buildPortraitLayout(
                                context, colorScheme, textTheme),
                      ),
                    ),
                  )),
            ),

            // Tap to continue indicator
            Positioned(
              bottom: 16.h,
              right: 0,
              left: 0,
              child: Obx(() => AnimatedOpacity(
                    opacity: controller.isAnimationComplete.value ? 0.7 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Text(
                        "Tap to continue",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bismillah logo
        _buildLogoPicture(colorScheme),
        SizedBox(height: 32.h), // Increased spacing

        // Quote
        _buildQuoteContainer(context, colorScheme, textTheme),

        // Progress indicator
        SizedBox(height: 32.h), // Increased spacing
        _buildProgressIndicator(colorScheme),
      ],
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side - Bismillah Logo
        Expanded(
          flex: 3,
          child: _buildLogoPicture(colorScheme),
        ),

        SizedBox(width: 16.w),

        // Right side - Quote and progress indicator
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuoteContainer(context, colorScheme, textTheme),
              SizedBox(height: 24.h),
              _buildProgressIndicator(colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPicture(ColorScheme colorScheme) {
    // Increase size for better visibility
    final logoSize = (Get.width < 600) ? 150.w : 130.w;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(
              top: 8.h), // Slight adjustment for vertical centering
          child: Text(
            '﷽',
            style: TextStyle(
              fontSize: logoSize * 0.45,
              color: colorScheme.primary.withOpacity(0.85),
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteContainer(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Container(
      constraints: BoxConstraints(maxHeight: isTablet ? 350.h : 300.h),
      padding: EdgeInsets.symmetric(horizontal: 24.r, vertical: 20.r),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quote Text with proper alignment
          Flexible(
            child: Center(
              child: SingleChildScrollView(
                child: Obx(() {
                  if (!controller.isQuoteLoaded.value) {
                    return _buildLoadingPlaceholder(context);
                  }

                  // Choose text direction based on content
                  final isUrdu = controller.isUrduQuote.value;
                  final hasTranslation =
                      isUrdu && controller.quoteTranslation.value.isNotEmpty;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Original quote
                      Directionality(
                        textDirection:
                            isUrdu ? TextDirection.rtl : TextDirection.ltr,
                        child: Align(
                          alignment:
                              isUrdu ? Alignment.centerRight : Alignment.center,
                          child: AnimatedTextKit(
                            onFinished: () {
                              // Only mark animation as complete if no translation or after showing translation
                              if (!hasTranslation) {
                                controller.onAnimationComplete();
                              }
                            },
                            animatedTexts: [
                              TypewriterAnimatedText(
                                controller.quoteText.value,
                                textStyle: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontSize: isTablet ? 20.sp : 18.sp,
                                  fontStyle: isUrdu ? null : FontStyle.italic,
                                  fontFamily:
                                      isUrdu ? 'JameelNooriNastaleeq' : null,
                                  height: isUrdu ? 1.8 : 1.5,
                                ),
                                textAlign:
                                    isUrdu ? TextAlign.right : TextAlign.center,
                                speed: const Duration(milliseconds: 40),
                              ),
                            ],
                            totalRepeatCount: 1,
                            displayFullTextOnTap: true,
                          ),
                        ),
                      ),

                      // Translation (if available)
                      if (hasTranslation) ...[
                        SizedBox(height: 16.h),
                        Divider(
                          color: colorScheme.primary.withOpacity(0.15),
                          thickness: 0.7,
                          indent: 16.w,
                          endIndent: 16.w,
                        ),
                        SizedBox(height: 12.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 30.h,
                                margin: EdgeInsets.only(right: 8.w),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: AnimatedTextKit(
                                  onFinished: () {
                                    controller.onAnimationComplete();
                                  },
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      controller.quoteTranslation.value,
                                      textStyle: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.8),
                                        fontSize: isTablet ? 16.sp : 14.sp,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.left,
                                      speed: const Duration(milliseconds: 20),
                                    ),
                                  ],
                                  totalRepeatCount: 1,
                                  displayFullTextOnTap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Attribution
          Obx(() => AnimatedOpacity(
                opacity: controller.isQuoteLoaded.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "- Allama Muhammad Iqbal",
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return SizedBox(
      width: Get.width * 0.5,
      child: Obx(() => LinearProgressIndicator(
            value: controller.loadingProgress.value,
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.primary.withOpacity(0.7),
            ),
            borderRadius: BorderRadius.circular(2),
            minHeight: 2,
          )),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return SizedBox(
      height: 100.h,
      child: Center(
        child: Text(
          "Loading wisdom...",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16.sp,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Custom painter for drawing an Islamic-inspired background pattern
class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw geometric patterns inspired by Islamic art
    const double spacing = 60;

    // Draw star pattern
    final starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    // Draw geometric grid
    for (double y = 0; y < size.height; y += spacing * 2) {
      for (double x = 0; x < size.width; x += spacing * 2) {
        _drawGeometricPattern(canvas, Offset(x, y), spacing, starPaint);
      }
    }

    // Draw circles for additional Islamic geometric feel
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    for (int i = 0; i < 4; i++) {
      final x = size.width / 2;
      final y = size.height / 2;
      final radius = (i + 1) * spacing * 2;
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  void _drawGeometricPattern(
      Canvas canvas, Offset center, double size, Paint paint) {
    // Draw a simple Islamic geometric pattern
    final halfSize = size / 2;
    final quarterSize = size / 4;

    // Draw a diamond
    final path = Path();
    path.moveTo(center.dx, center.dy - halfSize);
    path.lineTo(center.dx + halfSize, center.dy);
    path.lineTo(center.dx, center.dy + halfSize);
    path.lineTo(center.dx - halfSize, center.dy);
    path.close();

    canvas.drawPath(path, paint);

    // Draw internal lines
    canvas.drawLine(
      Offset(center.dx - halfSize, center.dy),
      Offset(center.dx + halfSize, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - halfSize),
      Offset(center.dx, center.dy + halfSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
