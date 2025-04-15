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
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'pdf_creator.dart';

/// Helper class to find RenderRepaintBoundary in the render tree
class FindRenderObjectVisitor {
  RenderObject? foundObject;
}

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
          if (!result.isGranted) {
            // Try requesting manage external storage as fallback
            final manageStorage = await Permission.manageExternalStorage.status;
            if (manageStorage.isDenied) {
              final manageResult =
                  await Permission.manageExternalStorage.request();
              return manageResult.isGranted;
            }
            return manageStorage.isGranted;
          }
          return result.isGranted;
        }
        return photos.isGranted;
      } else {
        final storage = await Permission.storage.status;
        if (storage.isDenied) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            // Try requesting manage external storage as fallback
            final manageStorage = await Permission.manageExternalStorage.status;
            if (manageStorage.isDenied) {
              final manageResult =
                  await Permission.manageExternalStorage.request();
              return manageResult.isGranted;
            }
            return manageStorage.isGranted;
          }
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
    try {
      // Check permissions first
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Storage permission is required');
      }

      // Create a unique subfolder for sharing files
      final tempDir = await getTemporaryDirectory();
      final shareDir = Directory('${tempDir.path}/iqbal_shares');
      if (!await shareDir.exists()) {
        await shareDir.create(recursive: true);
      }

      // Clear old temporary files
      await _clearOldFiles(shareDir);

      // Generate a unique filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFilename = '${filename}_$timestamp.png';
      final filePath = '${shareDir.path}/$uniqueFilename';

      // Capture widget to image using RepaintBoundary
      final boundary = _findRepaintBoundary(contentWidget);
      if (boundary == null) {
        throw Exception('Could not find repaint boundary in widget');
      }

      // Try to capture with different pixel ratios if necessary (fallback mechanism)
      Uint8List? pngBytes = await _captureWidgetWithFallback(boundary);
      if (pngBytes == null) {
        throw Exception('Failed to capture widget as image');
      }

      // Save image to file
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share the file using share_plus
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Shared via Iqbal Literature',
        subject: 'Iqbal Literature Verse',
      );

      // Don't delete right away, as some share handlers may access the file after the share sheet is dismissed
      // File cleanup will happen on next run via _clearOldFiles
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (e.toString().contains('permission')) {
        _showPermissionErrorSnackbar(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }

  // Helper method to find RepaintBoundary in widget
  static RenderRepaintBoundary? _findRepaintBoundary(Widget widget) {
    try {
      // Wait for the next frame to ensure the widget is built
      RenderRepaintBoundary? boundary;

      // If the widget is passed as a GlobalKey<State> based widget
      if (widget is RepaintBoundary && widget.key is GlobalKey) {
        final key = widget.key as GlobalKey;
        if (key.currentContext != null) {
          final renderObject = key.currentContext!.findRenderObject();
          if (renderObject is RenderRepaintBoundary) {
            boundary = renderObject;
          }
        }
      } else if (widget.key is GlobalKey) {
        final key = widget.key as GlobalKey;
        if (key.currentContext != null) {
          // Try to find the first RenderRepaintBoundary in the subtree
          final renderObject = key.currentContext!.findRenderObject();
          FindRenderObjectVisitor visitor = FindRenderObjectVisitor();
          visitChildElements(key.currentContext!.findRenderObject(), visitor);
          boundary = visitor.foundObject as RenderRepaintBoundary?;
        }
      }

      return boundary;
    } catch (e) {
      debugPrint('Error finding repaint boundary: $e');
      return null;
    }
  }

  // Visitor pattern to find RenderRepaintBoundary in the render tree
  static void visitChildElements(
      RenderObject? renderObject, FindRenderObjectVisitor visitor) {
    if (renderObject == null) return;
    if (renderObject is RenderRepaintBoundary) {
      visitor.foundObject = renderObject;
      return;
    }

    // Continue searching
    renderObject.visitChildren((child) {
      visitChildElements(child, visitor);
    });
  }

  static Future<Uint8List?> _captureWidgetWithFallback(
      RenderRepaintBoundary boundary) async {
    // Try with high resolution first, then fall back to lower resolutions
    final pixelRatios = [3.0, 2.0, 1.5, 1.0];

    for (final ratio in pixelRatios) {
      try {
        final ui.Image image = await boundary.toImage(pixelRatio: ratio);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('Error capturing with pixel ratio $ratio: $e');
        // Continue to next pixel ratio
        continue;
      }
    }

    return null; // All attempts failed
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

  static void _showPermissionErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Storage permission is required to share files',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }
}
