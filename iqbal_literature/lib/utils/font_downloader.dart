import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Utility to ensure Urdu fonts are available, with fallback download support
class FontDownloader {
  static const String notoNastaliqUrduUrl =
      'https://github.com/google/fonts/raw/main/ofl/notonastaliqurdu/NotoNastaliqUrdu-Regular.ttf';

  static const String scheherazadeNewUrl =
      'https://github.com/google/fonts/raw/main/ofl/scheherazadenew/ScheherazadeNew-Regular.ttf';

  static const Map<String, String> _availableFontUrls = {
    'NotoNastaliqUrdu-Regular.ttf': notoNastaliqUrduUrl,
    'ScheherazadeNew-Regular.ttf': scheherazadeNewUrl,
  };

  /// Check if required Urdu font exists and download if missing
  static Future<String?> ensureUrduFontAvailable() async {
    try {
      // Check if any of the bundled fonts exist
      final bool hasJameelNoori =
          await _checkAssetExists('assets/fonts/JameelNooriNastaleeq.ttf');
      final bool hasJameelNooriAlt = await _checkAssetExists(
          'assets/fonts/Jameel-Noori-Nastaleeq-Regular.ttf');
      final bool hasAlviNastaleeq =
          await _checkAssetExists('assets/fonts/Alvi-Nastaleeq-Regular.ttf');
      final bool hasNotoNastaliq =
          await _checkAssetExists('assets/fonts/NotoNastaliqUrdu-Regular.ttf');

      if (hasJameelNoori ||
          hasJameelNooriAlt ||
          hasAlviNastaleeq ||
          hasNotoNastaliq) {
        debugPrint('✅ Found bundled Urdu font');
        return null; // No download needed
      }

      // Check if we already have any downloaded fonts
      final docDir = await getApplicationDocumentsDirectory();

      // Try each font in preference order
      for (final fontName in _availableFontUrls.keys) {
        final fontPath = '${docDir.path}/$fontName';
        final fontFile = File(fontPath);

        if (await fontFile.exists()) {
          final fileSize = await fontFile.length();
          if (fileSize > 0) {
            debugPrint('✅ Using previously downloaded font: $fontName');
            return fontPath;
          } else {
            // Delete corrupt/empty font file and try to download again
            await fontFile.delete();
          }
        }
      }

      // If no fonts found, download in order of preference
      return await _downloadFonts();
    } catch (e) {
      debugPrint('❌ Error ensuring Urdu font: $e');
      return null;
    }
  }

  /// Check if a font asset exists in the bundle
  static Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Download fonts in order of preference
  static Future<String?> _downloadFonts() async {
    debugPrint('⬇️ Attempting to download fonts...');

    final docDir = await getApplicationDocumentsDirectory();

    // Try each font in sequence
    for (final entry in _availableFontUrls.entries) {
      final fontName = entry.key;
      final fontUrl = entry.value;

      try {
        debugPrint('⬇️ Downloading $fontName...');

        final response = await http.get(Uri.parse(fontUrl)).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Font download timed out');
          },
        );

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final fontPath = '${docDir.path}/$fontName';
          final fontFile = File(fontPath);

          await fontFile.writeAsBytes(response.bodyBytes);

          // Verify the file was written correctly
          if (await fontFile.exists() && await fontFile.length() > 0) {
            debugPrint('✅ Downloaded $fontName to: $fontPath');
            return fontPath;
          } else {
            debugPrint(
                '⚠️ Downloaded font file is empty or corrupt: $fontPath');
          }
        } else {
          debugPrint(
              '❌ Failed to download $fontName: HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Error downloading $fontName: $e');
        // Continue to next font
      }
    }

    debugPrint('❌ All font downloads failed');
    return null;
  }

  /// Pre-download fonts in the background for faster PDF creation later
  static Future<void> preloadFonts() async {
    try {
      debugPrint('🔄 Preloading fonts in background...');
      await ensureUrduFontAvailable();
      debugPrint('✅ Font preloading complete');
    } catch (e) {
      debugPrint('⚠️ Font preloading failed: $e');
    }
  }
}

/// Exception for font download timeouts
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
