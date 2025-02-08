import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
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
  }) async {
    GlobalKey previewContainer = GlobalKey();
    OverlayEntry? overlayEntry;
    
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Please grant storage access in Settings to share images');
      }

      // Create temporary directory
      final temp = await getTemporaryDirectory();
      final dir = Directory('${temp.path}/share_images');
      await dir.create(recursive: true);
      await _clearOldFiles(dir);

      // Create a unique filename
      final imagePath = '${dir.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.png';

      // Create and insert overlay
      final overlayState = Overlay.of(context);
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -9999,
          child: RepaintBoundary(
            key: previewContainer,
            child: Material(
              child: contentWidget,
            ),
          ),
        ),
      );
      
      overlayState.insert(overlayEntry);
      
      // Wait for widget to be rendered
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the image using the GlobalKey
      final renderObject = previewContainer.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) throw Exception('Failed to find render boundary');

      final imageBytes = await ScreenshotUtil.captureWidget(renderObject);
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
