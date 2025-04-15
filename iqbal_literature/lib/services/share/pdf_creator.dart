import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // Using Syncfusion for image embedding

/// Generates a multi-page PDF for poems by rendering content chunk by chunk
/// into images and embedding each image onto a separate PDF page.
class IqbalPdfGenerator {
  static const String watermark = 'Shared via Iqbal Literature';
  // Define the font family to be used within the Flutter widget rendering
  static const String urduFontFamily = 'JameelNooriNastaleeq';

  // --- Constants for Layout --- (Adjust as needed)
  static const double _pageWidthPoints = 595.0; // Standard A4 width in points
  static const double _pageHeightPoints = 842.0; // Standard A4 height in points
  static const double _horizontalPadding = 40.0;
  static const double _verticalPadding = 50.0;
  static const double _titleBottomSpacing = 30.0;
  static const double _watermarkTopSpacing = 40.0;
  static const double _contentLineHeight = 2.0;
  static const double _titleFontSize = 28.0;
  static const double _contentFontSize = 18.0;
  static const double _watermarkFontSize = 10.0;
  // -----------------------------

  /// Generate and share a multi-page PDF of a poem.
  static Future<bool> sharePoemPdf(
    BuildContext context,
    String title,
    String content,
    String filename, {
    bool landscape = false, // Note: Pagination logic assumes portrait for now
  }) async {
    // Local function to safely pop dialog if context is still mounted
    void safePopDialog() {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    // Local function to show snackbar if context is mounted
    void showSnackbar(String message, {bool isError = true}) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : Colors.green,
          ),
        );
      }
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      debugPrint('Starting multi-page PDF generation...');

      // 1. Estimate text heights and split content into page chunks
      final contentChunks = await _splitContentIntoPages(
        context,
        title,
        content,
      );
      if (contentChunks.isEmpty) {
        safePopDialog();
        throw Exception('Could not split content into pages.');
      }
      debugPrint('Content split into ${contentChunks.length} page(s).');

      // 2. Generate an image for each page chunk
      List<Uint8List> pageImages = [];
      for (int i = 0; i < contentChunks.length; i++) {
        debugPrint('Generating image for page ${i + 1}...');
        final imageData = await _generateSinglePageImage(
          context,
          title,
          contentChunks[i],
          pageNumber: i + 1,
          totalPages: contentChunks.length,
        );
        if (imageData == null) {
          safePopDialog();
          throw Exception('Failed to generate image for page ${i + 1}.');
        }
        pageImages.add(imageData);
      }
      debugPrint('All page images generated successfully.');

      // 3. Create the multi-page PDF from the images
      final pdfPath = await _generateMultiPageImagePdf(
        pageImages,
        filename,
        // Use portrait as pagination logic is based on it
        pageOrientation: PdfPageOrientation.portrait,
      );
      if (pdfPath.isEmpty) {
        safePopDialog();
        throw Exception('Failed to generate multi-page PDF document.');
      }
      debugPrint('Multi-page PDF generated successfully at: $pdfPath');

      // 4. Share the generated PDF file
      await Share.shareXFiles([XFile(pdfPath)],
          text: 'Iqbal Literature - $title',
          subject: 'Iqbal Literature - $title');

      // Close the loading dialog AFTER the share sheet has been invoked
      safePopDialog(); // <-- ADD THIS LINE HERE

      return true;
    } catch (e) {
      debugPrint('❌ Multi-Page PDF Sharing Error: $e');
      safePopDialog(); // Ensure dialog is closed on error
      showSnackbar('Failed to share PDF: ${e.toString()}');
      return false;
    }
  }

  /// Measures text height using TextPainter.
  static double _measureTextHeight(
      String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    )..layout(maxWidth: maxWidth);
    return textPainter.height;
  }

  /// Splits the content string into chunks that should fit on individual pages.
  static Future<List<String>> _splitContentIntoPages(
    BuildContext context,
    String title,
    String content,
  ) async {
    final List<String> chunks = [];
    final lines = content.split('\n');
    List<String> currentChunkLines = [];

    final double pageDrawableWidth =
        _pageWidthPoints - (2 * _horizontalPadding);
    final double pageDrawableHeight =
        _pageHeightPoints - (2 * _verticalPadding);

    // Calculate heights of fixed elements
    final titleStyle = TextStyle(
        fontFamily: urduFontFamily,
        fontSize: _titleFontSize,
        fontWeight: FontWeight.bold,
        height: _contentLineHeight);
    final contentStyle = TextStyle(
        fontFamily: urduFontFamily,
        fontSize: _contentFontSize,
        height: _contentLineHeight);
    final watermarkStyle = TextStyle(fontSize: _watermarkFontSize);

    final titleHeight =
        _measureTextHeight(title, titleStyle, pageDrawableWidth);
    final watermarkHeight =
        _measureTextHeight(watermark, watermarkStyle, pageDrawableWidth);
    final pageNumberHeight = _measureTextHeight("Page 1 / 1", watermarkStyle,
        pageDrawableWidth); // Estimate page number height

    final double availableHeightFirstPage = pageDrawableHeight -
        titleHeight -
        _titleBottomSpacing -
        watermarkHeight -
        _watermarkTopSpacing -
        pageNumberHeight;
    final double availableHeightSubsequentPages = pageDrawableHeight -
        watermarkHeight -
        _watermarkTopSpacing -
        pageNumberHeight; // No title on subsequent pages

    double currentChunkHeight = 0;
    bool isFirstPage = true;

    for (final line in lines) {
      final lineHeight = _measureTextHeight(
          line.isEmpty ? " " : line, contentStyle, pageDrawableWidth);
      final availableHeight = isFirstPage
          ? availableHeightFirstPage
          : availableHeightSubsequentPages;

      if (currentChunkHeight + lineHeight <= availableHeight) {
        currentChunkLines.add(line);
        currentChunkHeight += lineHeight;
      } else {
        // Current line doesn't fit, finalize the previous chunk
        if (currentChunkLines.isNotEmpty) {
          chunks.add(currentChunkLines.join('\n'));
        }
        // Start a new chunk with the current line
        currentChunkLines = [line];
        currentChunkHeight = lineHeight;
        isFirstPage =
            false; // Subsequent pages don't have the title space constraint
      }
    }

    // Add the last chunk if it has content
    if (currentChunkLines.isNotEmpty) {
      chunks.add(currentChunkLines.join('\n'));
    }

    return chunks;
  }

  /// Generates an image for a single page's content chunk.
  static Future<Uint8List?> _generateSinglePageImage(
      BuildContext context, String title, String contentChunk,
      {required int pageNumber, required int totalPages}) async {
    final GlobalKey repaintKey = GlobalKey();
    final bool isFirstPage = pageNumber == 1;
    final bool isLastPage = pageNumber == totalPages;

    final Widget pageWidget = RepaintBoundary(
      key: repaintKey,
      child: Material(
        color: Colors.white,
        child: Container(
          // Use fixed A4 size in points for predictable rendering
          width: _pageWidthPoints,
          height: _pageHeightPoints,
          padding: EdgeInsets.symmetric(
              horizontal: _horizontalPadding, vertical: _verticalPadding),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title (only on first page)
                if (isFirstPage)
                  Text(
                    title,
                    style: TextStyle(
                        fontFamily: urduFontFamily,
                        fontSize: _titleFontSize,
                        fontWeight: FontWeight.bold,
                        height: _contentLineHeight),
                    textAlign: TextAlign.center,
                  ),
                if (isFirstPage) SizedBox(height: _titleBottomSpacing),

                // Content for this page
                Text(
                  contentChunk,
                  style: TextStyle(
                      fontFamily: urduFontFamily,
                      fontSize: _contentFontSize,
                      height: _contentLineHeight),
                  textAlign: TextAlign.right,
                ),

                const Spacer(), // Push footer to bottom

                // Footer: Watermark and Page Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLastPage
                          ? watermark
                          : '', // Watermark maybe only on last page?
                      style: TextStyle(
                          fontSize: _watermarkFontSize,
                          color: Colors.grey[600]),
                    ),
                    Text(
                      'Page $pageNumber / $totalPages',
                      style: TextStyle(
                          fontSize: _watermarkFontSize,
                          color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // --- Off-screen rendering --- (Similar to previous implementation)
    try {
      final OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) =>
            Positioned(top: -9999, left: -9999, child: pageWidget),
      );
      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(
          const Duration(milliseconds: 150)); // Shorter delay maybe ok

      final RenderRepaintBoundary? boundary = repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        throw Exception(
            'Could not find RenderRepaintBoundary for page $pageNumber.');
      }

      // Use pixelRatio 2.0 for balance between quality and file size
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      overlayEntry.remove();
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) {
        throw Exception(
            'Failed to convert captured image to byte data for page $pageNumber.');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error generating image for page $pageNumber: $e');
      return null;
    }
  }

  /// Creates a multi-page PDF document from a list of page images.
  static Future<String> _generateMultiPageImagePdf(
      List<Uint8List> pageImages, String filename,
      {PdfPageOrientation pageOrientation =
          PdfPageOrientation.portrait}) async {
    try {
      final filePath = await _prepareStorageForPdf(filename);
      final PdfDocument document = PdfDocument();
      document.pageSettings.orientation = pageOrientation;
      // Ensure consistent margins matching the rendered widget if needed, though image fills page here
      // document.pageSettings.margins.all = 0; // Example if image should fill completely

      for (final imageData in pageImages) {
        final PdfPage page = document.pages.add();
        final Size pageSize = page.getClientSize();
        final PdfBitmap pdfImage = PdfBitmap(imageData);

        // Draw the image to fill the page (adjust if padding is desired)
        page.graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
        );
      }

      final List<int> bytes = await document.save();
      document.dispose();

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('Multi-page image-based PDF saved successfully to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generating multi-page PDF: $e');
      return '';
    }
  }

  /// Prepares the temporary storage directory and generates a unique file path.
  static Future<String> _prepareStorageForPdf(String filename) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final Directory shareDir = Directory('${tempDir.path}/iqbal_pdf_shares');
      // Create the directory if it doesn't exist
      if (!await shareDir.exists()) {
        await shareDir.create(recursive: true);
      }
      // Clean up old files potentially
      _clearOldFiles(shareDir); // Optional: Add cleanup logic

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // Sanitize filename (basic example)
      final String safeFilename =
          filename.replaceAll(RegExp(r'[\/\\:*?"<>|]'), '_');
      return '${shareDir.path}/${safeFilename}_$timestamp.pdf';
    } catch (e) {
      debugPrint('Error preparing storage: $e');
      // Fallback path in case of error
      final Directory tempDir = await getTemporaryDirectory();
      return '${tempDir.path}/${filename}_fallback.pdf';
    }
  }

  /// Optional: Clears files older than a certain duration from the share directory.
  static Future<void> _clearOldFiles(Directory dir,
      {Duration maxAge = const Duration(hours: 24)}) async {
    try {
      if (await dir.exists()) {
        final DateTime now = DateTime.now();
        dir.list().listen((FileSystemEntity entity) {
          if (entity is File) {
            entity.stat().then((FileStat stat) {
              if (now.difference(stat.modified) > maxAge) {
                entity.delete().catchError((e) =>
                    debugPrint('Error deleting old file ${entity.path}: $e'));
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error clearing old files: $e');
    }
  }
}
