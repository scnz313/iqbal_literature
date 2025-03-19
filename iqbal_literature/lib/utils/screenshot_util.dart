import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class ScreenshotUtil {
  /// Captures a widget as a high-quality image
  /// Uses a higher pixel ratio for sharper images
  static Future<Uint8List?> captureWidget(RenderRepaintBoundary boundary,
      {double pixelRatio = 3.0}) async {
    try {
      // Use a higher pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      print('Error capturing screenshot: $e');
      // If the initial capture fails with high resolution, try again with a lower resolution
      if (pixelRatio > 1.5) {
        return captureWidget(boundary, pixelRatio: 1.5);
      }
    }
    return null;
  }

  /// Calculate the optimal pixel ratio based on content size
  /// This helps prevent memory issues with very large content
  static double calculateOptimalPixelRatio(double contentWidth) {
    // For very large content, reduce the pixel ratio to avoid memory issues
    if (contentWidth > 1000) {
      return 1.5;
    } else if (contentWidth > 600) {
      return 2.0;
    }
    return 3.0; // Default high quality for most content
  }
}
