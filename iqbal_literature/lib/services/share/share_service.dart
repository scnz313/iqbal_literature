import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../../utils/screenshot_util.dart';

class ShareService {
  static Future<void> shareAsText(String title, String content) async {
    try {
      final text = '$title\n\n$content\n\nShared via Iqbal Literature';
      await Share.share(text);
    } catch (e) {
      debugPrint('Error sharing text: $e');
      rethrow;
    }
  }

  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final photos = await Permission.photos.status;
        if (photos.isDenied) {
          final result = await Permission.photos.request();
          return result.isGranted;
        }
        return photos.isGranted;
      } else {
        final storage = await Permission.storage.status;
        if (storage.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return storage.isGranted;
      }
    }

    if (Platform.isIOS) {
      final photos = await Permission.photos.status;
      if (photos.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }
      return photos.isGranted;
    }

    return false;
  }

  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  static Future<void> shareAsImage(
    BuildContext context,
    Widget contentWidget,
    String filename, {
    bool showWatermark = true,
    String? backgroundImage,
    Color backgroundColor = Colors.white,
    double containerWidth = 800,
  }) async {
    GlobalKey previewContainer = GlobalKey();
    OverlayEntry? overlayEntry;

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception(
            'Please grant storage access in Settings to share images');
      }

      // Create temporary directory
      final temp = await getTemporaryDirectory();
      final dir = Directory('${temp.path}/share_images');
      await dir.create(recursive: true);
      await _clearOldFiles(dir);

      // Create a unique filename
      final imagePath =
          '${dir.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.png';

      // Validate background image path if provided
      if (backgroundImage != null) {
        try {
          // Check if asset exists
          await rootBundle.load(backgroundImage);
        } catch (e) {
          // Asset not found, use null instead
          debugPrint('Background image not found: $backgroundImage');
          backgroundImage = null;
        }
      }

      // Create and insert overlay with responsive width
      final overlayState = Overlay.of(context);
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -9999,
          child: RepaintBoundary(
            key: previewContainer,
            child: Container(
              width: containerWidth,
              decoration: BoxDecoration(
                color: backgroundColor,
                image: backgroundImage != null
                    ? DecorationImage(
                        image: AssetImage(backgroundImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(30),
              child: Material(
                color: Colors.transparent,
                child: contentWidget,
              ),
            ),
          ),
        ),
      );

      overlayState.insert(overlayEntry);

      // Wait for widget to be rendered
      await Future.delayed(const Duration(milliseconds: 200));

      // Capture the image using the GlobalKey
      final renderObject = previewContainer.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (renderObject == null)
        throw Exception('Failed to find render boundary');

      // Calculate optimal pixel ratio based on content width
      final pixelRatio =
          ScreenshotUtil.calculateOptimalPixelRatio(containerWidth);

      // Capture with optimal resolution
      final imageBytes = await ScreenshotUtil.captureWidget(renderObject,
          pixelRatio: pixelRatio);
      if (imageBytes == null) throw Exception('Failed to capture screenshot');

      // Save and share
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Shared via Iqbal Literature',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      rethrow;
    } finally {
      overlayEntry?.remove();
    }
  }

  // Create a content widget that can be used for both image capture and PDF generation
  static Widget createContentWidget(
    String title,
    String content, {
    String? backgroundImage,
    Color backgroundColor = Colors.white,
    double width = 800,
    double fontSize = 18.0,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
                opacity: 0.3,
              )
            : null,
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'JameelNooriNastaleeq',
              fontSize: fontSize + 6, // Larger font for title
              height: 2,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'JameelNooriNastaleeq',
              fontSize: fontSize,
              height: 2,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // New implementation that uses image-based approach for PDF generation
  static Future<void> shareAsPdf(
    BuildContext context,
    String title,
    String content,
    String filename, {
    String? backgroundImagePath,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) async {
    GlobalKey previewContainer = GlobalKey();
    OverlayEntry? overlayEntry;

    try {
      debugPrint('🚀 Starting PDF generation using image-based approach');
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Please grant storage access in Settings to share PDF');
      }

      // Create temporary directory
      final temp = await getTemporaryDirectory();
      final dir = Directory('${temp.path}/share_pdfs');
      await dir.create(recursive: true);
      await _clearOldFiles(dir);

      // Create a unique filename
      final pdfPath =
          '${dir.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Validate background image
      if (backgroundImagePath != null) {
        try {
          await rootBundle.load(backgroundImagePath);
        } catch (e) {
          debugPrint('Background image not found: $backgroundImagePath');
          backgroundImagePath = null;
        }
      }

      // Split content into pages (approximately 15 lines per page)
      final contentLines = content.split('\n');
      const int linesPerPage = 15;
      final int pageCount = max(1, (contentLines.length / linesPerPage).ceil());
      debugPrint(
          '📝 Content has ${contentLines.length} lines, creating $pageCount pages');

      // Create PDF document
      final pdf = pw.Document();
      final List<Uint8List> pageImages = [];
      final overlayState = Overlay.of(context);

      // Generate images for each page
      for (int i = 0; i < pageCount; i++) {
        final int startLine = i * linesPerPage;
        final int endLine = min((i + 1) * linesPerPage, contentLines.length);
        if (startLine >= contentLines.length) continue;

        final List<String> pageLines = contentLines.sublist(startLine, endLine);
        final String pageContent = pageLines.join('\n');

        // Only show title on first page
        final String pageTitle = i == 0 ? title : '';

        // Create content widget for this page
        final contentWidget = Material(
          color: Colors.transparent,
          child: createContentWidget(
            pageTitle,
            pageContent,
            backgroundImage: backgroundImagePath,
            backgroundColor: backgroundColor,
            width: 595.0, // A4 width in points at 72 DPI
          ),
        );

        // Capture image using overlay method (similar to shareAsImage)
        final Uint8List? imageData =
            await _capturePageAsImage(context, contentWidget, overlayState);

        if (imageData != null) {
          pageImages.add(imageData);
        }
      }

      // Add each page image to the PDF
      for (int i = 0; i < pageImages.length; i++) {
        final pageImage = pageImages[i];
        final pwImage = pw.MemoryImage(pageImage);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Page content from captured image
                  pw.Positioned.fill(
                    child: pw.Image(pwImage, fit: pw.BoxFit.contain),
                  ),

                  // Footer
                  pw.Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Shared via Iqbal Literature',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          'Page ${i + 1} of ${pageImages.length}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save the PDF
      debugPrint(
          '📄 Saving PDF with ${pdf.document.pdfPageList.pages.length} pages');
      final file = File(pdfPath);
      final pdfBytes = await pdf.save();

      if (pdfBytes.isEmpty) {
        throw Exception('Generated PDF is empty');
      }

      debugPrint('💾 PDF saved successfully: ${pdfBytes.length} bytes');
      await file.writeAsBytes(pdfBytes);

      if (!file.existsSync() || await file.length() == 0) {
        throw Exception('Failed to save PDF file');
      }

      // Share the PDF
      debugPrint('📤 Sharing PDF file: ${file.path}');
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: 'Shared via Iqbal Literature',
      );
      debugPrint('✅ PDF shared successfully');
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }

  // Helper method to capture a page as an image using overlay method
  static Future<Uint8List?> _capturePageAsImage(
    BuildContext context,
    Widget contentWidget,
    OverlayState overlayState, {
    double pixelRatio = 3.0,
  }) async {
    final GlobalKey previewContainer = GlobalKey();
    OverlayEntry? overlayEntry;

    try {
      // Create and insert overlay with the content widget
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -9999, // Position off-screen
          child: RepaintBoundary(
            key: previewContainer,
            child: contentWidget,
          ),
        ),
      );

      overlayState.insert(overlayEntry);

      // Wait for widget to be rendered
      await Future.delayed(const Duration(milliseconds: 300));

      // Capture the image using the GlobalKey
      final renderObject = previewContainer.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (renderObject == null) {
        throw Exception('Failed to find render boundary for PDF page');
      }

      // Capture with optimal resolution
      final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing page as image: $e');
      return null;
    } finally {
      overlayEntry?.remove();
    }
  }

  static Future<void> _clearOldFiles(Directory dir) async {
    try {
      if (await dir.exists()) {
        final files = dir.listSync();
        final now = DateTime.now();
        for (var file in files) {
          if (file is File) {
            final stat = await file.stat();
            final age = now.difference(stat.modified);
            if (age.inHours > 24) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing old files: $e');
    }
  }
}
