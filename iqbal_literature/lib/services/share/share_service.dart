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
      // Convert widget to image
      final RenderRepaintBoundary boundary =
          contentWidget.key as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename.png';

      // Save image to temporary file
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share the file using share_plus
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Iqbal Literature',
      );

      // Clean up temporary file after sharing
      await file.delete();
    } catch (e) {
      debugPrint('Error sharing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> shareAsPdf(
    BuildContext context,
    String title,
    String content,
    String filename, {
    String? backgroundImagePath,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                content,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(textColor.value),
                ),
              ),
            );
          },
        ),
      );

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename.pdf';

      // Save PDF to temporary file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share the file using share_plus
      await Share.shareXFiles(
        [XFile(filePath)],
        text: title,
        subject: 'Iqbal Literature - $title',
      );

      // Clean up temporary file after sharing
      await file.delete();
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
