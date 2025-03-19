import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// This script generates background patterns for sharing poetry
/// Run this with:
/// flutter run -d macos scripts/generate_backgrounds.dart
/// (or use your desired platform in place of macos)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BackgroundGeneratorApp());
}

class BackgroundGeneratorApp extends StatelessWidget {
  const BackgroundGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BackgroundGeneratorScreen(),
    );
  }
}

class BackgroundGeneratorScreen extends StatefulWidget {
  const BackgroundGeneratorScreen({super.key});

  @override
  State<BackgroundGeneratorScreen> createState() =>
      _BackgroundGeneratorScreenState();
}

class _BackgroundGeneratorScreenState extends State<BackgroundGeneratorScreen> {
  final List<String> backgroundTypes = [
    'Calligraphy Patterns',
    'Geometric Patterns',
    'Paper Textures',
    'Subtle Gradients',
    'Islamic Patterns',
  ];

  bool isGenerating = false;
  String status = '';

  Future<void> generateBackgrounds() async {
    setState(() {
      isGenerating = true;
      status = 'Starting background generation...';
    });

    try {
      // Create backgrounds directory if it doesn't exist
      final String outputDir = 'assets/images/backgrounds';
      Directory(outputDir).createSync(recursive: true);

      // Generate each type of background
      setState(() => status = 'Generating calligraphy patterns...');
      await _generateCalligraphyPatterns(outputDir);

      setState(() => status = 'Generating geometric patterns...');
      await _generateGeometricPatterns(outputDir);

      setState(() => status = 'Generating paper textures...');
      await _generatePaperTextures(outputDir);

      setState(() => status = 'Generating subtle gradients...');
      await _generateSubtleGradients(outputDir);

      setState(() => status = 'Generating Islamic patterns...');
      await _generateIslamicPatterns(outputDir);

      setState(() => status = 'All backgrounds generated successfully!');
    } catch (e) {
      setState(() => status = 'Error generating backgrounds: $e');
    } finally {
      setState(() => isGenerating = false);
    }
  }

  Future<void> _generateCalligraphyPatterns(String outputDir) async {
    final GlobalKey key = GlobalKey();
    final colors = [
      Colors.indigo.withOpacity(0.2),
      Colors.teal.withOpacity(0.2),
      Colors.amber.withOpacity(0.2),
    ];

    for (int i = 0; i < colors.length; i++) {
      final pattern = RepaintBoundary(
        key: key,
        child: Container(
          width: 800,
          height: 1200,
          color: Colors.white,
          child: CustomPaint(
            painter: CalligraphyPatternPainter(color: colors[i]),
          ),
        ),
      );

      // Render and save
      final fileName = 'calligraphy_pattern_${i + 1}.png';
      await _renderAndSaveWidget(key, pattern, path.join(outputDir, fileName));
    }
  }

  Future<void> _generateGeometricPatterns(String outputDir) async {
    final GlobalKey key = GlobalKey();
    final colors = [
      Colors.blue.withOpacity(0.2),
      Colors.purple.withOpacity(0.2),
      Colors.green.withOpacity(0.2),
    ];

    for (int i = 0; i < colors.length; i++) {
      final pattern = RepaintBoundary(
        key: key,
        child: Container(
          width: 800,
          height: 1200,
          color: Colors.white,
          child: CustomPaint(
            painter: GeometricPatternPainter(color: colors[i]),
          ),
        ),
      );

      // Render and save
      final fileName = 'geometric_pattern_${i + 1}.png';
      await _renderAndSaveWidget(key, pattern, path.join(outputDir, fileName));
    }
  }

  Future<void> _generatePaperTextures(String outputDir) async {
    final GlobalKey key = GlobalKey();
    final textures = [
      0.1, // Light texture
      0.2, // Medium texture
      0.3, // Heavy texture
    ];

    for (int i = 0; i < textures.length; i++) {
      final pattern = RepaintBoundary(
        key: key,
        child: Container(
          width: 800,
          height: 1200,
          color: Colors.white,
          child: CustomPaint(
            painter: PaperTexturePainter(intensity: textures[i]),
          ),
        ),
      );

      // Render and save
      final fileName = 'paper_texture_${i + 1}.png';
      await _renderAndSaveWidget(key, pattern, path.join(outputDir, fileName));
    }
  }

  Future<void> _generateSubtleGradients(String outputDir) async {
    final GlobalKey key = GlobalKey();
    final gradients = [
      [Colors.blue.shade50, Colors.indigo.shade50],
      [Colors.amber.shade50, Colors.orange.shade50],
      [Colors.pink.shade50, Colors.purple.shade50],
    ];

    for (int i = 0; i < gradients.length; i++) {
      final pattern = RepaintBoundary(
        key: key,
        child: Container(
          width: 800,
          height: 1200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradients[i],
            ),
          ),
        ),
      );

      // Render and save
      final fileName = 'gradient_${i + 1}.png';
      await _renderAndSaveWidget(key, pattern, path.join(outputDir, fileName));
    }
  }

  Future<void> _generateIslamicPatterns(String outputDir) async {
    final GlobalKey key = GlobalKey();
    final colors = [
      Colors.teal.withOpacity(0.3),
      Colors.indigo.withOpacity(0.3),
      Colors.amber.withOpacity(0.3),
    ];

    for (int i = 0; i < colors.length; i++) {
      final pattern = RepaintBoundary(
        key: key,
        child: Container(
          width: 800,
          height: 1200,
          color: Colors.white,
          child: CustomPaint(painter: IslamicPatternPainter(color: colors[i])),
        ),
      );

      // Render and save
      final fileName = 'islamic_pattern_${i + 1}.png';
      await _renderAndSaveWidget(key, pattern, path.join(outputDir, fileName));
    }
  }

  Future<void> _renderAndSaveWidget(
    GlobalKey key,
    Widget widget,
    String outputPath,
  ) async {
    // Render the widget to the screen first (to ensure it's built)
    await Future.delayed(const Duration(milliseconds: 50));

    // Build the widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        RenderRepaintBoundary boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData != null) {
          final Uint8List pngBytes = byteData.buffer.asUint8List();
          File(outputPath).writeAsBytesSync(pngBytes);
          print('Saved: $outputPath');
        }
      } catch (e) {
        print('Error rendering: $e');
      }
    });

    // Wait for rendering to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Background Generator')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Generate Beautiful Backgrounds',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('This tool will generate the following backgrounds:'),
              const SizedBox(height: 10),
              ...backgroundTypes.map(
                (type) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $type'),
                ),
              ),
              const SizedBox(height: 30),
              if (isGenerating)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(status),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: generateBackgrounds,
                  child: const Text('Generate Backgrounds'),
                ),
              const SizedBox(height: 20),
              if (!isGenerating && status.isNotEmpty)
                Text(
                  status,
                  style: TextStyle(
                    color: status.contains('Error') ? Colors.red : Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pattern Painters

class CalligraphyPatternPainter extends CustomPainter {
  final Color color;

  CalligraphyPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final random = math.Random(42); // Fixed seed for reproducibility

    for (int i = 0; i < 100; i++) {
      final path = Path();
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;

      path.moveTo(startX, startY);

      for (int j = 0; j < 5; j++) {
        final controlX1 = startX + random.nextDouble() * 100 - 50;
        final controlY1 = startY + random.nextDouble() * 100 - 50;
        final controlX2 = startX + random.nextDouble() * 200 - 100;
        final controlY2 = startY + random.nextDouble() * 200 - 100;
        final endX = startX + random.nextDouble() * 300 - 150;
        final endY = startY + random.nextDouble() * 300 - 150;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, endX, endY);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GeometricPatternPainter extends CustomPainter {
  final Color color;

  GeometricPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final tileSize = 40.0;
    final rows = (size.height / tileSize).ceil();
    final cols = (size.width / tileSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * tileSize;
        final y = row * tileSize;

        // Alternate patterns
        final pattern = (row + col) % 4;

        if (pattern == 0) {
          // Squares
          canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), paint);
        } else if (pattern == 1) {
          // Circles
          canvas.drawCircle(
            Offset(x + tileSize / 2, y + tileSize / 2),
            tileSize / 2,
            paint,
          );
        } else if (pattern == 2) {
          // Diamonds
          final path = Path()
            ..moveTo(x + tileSize / 2, y)
            ..lineTo(x + tileSize, y + tileSize / 2)
            ..lineTo(x + tileSize / 2, y + tileSize)
            ..lineTo(x, y + tileSize / 2)
            ..close();
          canvas.drawPath(path, paint);
        } else {
          // Cross
          canvas.drawLine(
            Offset(x, y),
            Offset(x + tileSize, y + tileSize),
            paint,
          );
          canvas.drawLine(
            Offset(x + tileSize, y),
            Offset(x, y + tileSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperTexturePainter extends CustomPainter {
  final double intensity;

  PaperTexturePainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(12345);
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw grain
    for (int i = 0; i < 5000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final length = 2 + random.nextDouble() * 4;
      final angle = random.nextDouble() * math.pi;

      paint.color = Colors.black.withOpacity(0.05 * intensity);

      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * length, y + math.sin(angle) * length),
        paint,
      );
    }

    // Draw small dots
    for (int i = 0; i < 2000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      paint.color = Colors.black.withOpacity(0.03 * intensity);

      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final tileSize = 100.0;
    final rows = (size.height / tileSize).ceil() + 1;
    final cols = (size.width / tileSize).ceil() + 1;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final centerX = col * tileSize;
        final centerY = row * tileSize;

        // Draw star pattern
        _drawStarPattern(canvas, centerX, centerY, tileSize, paint);
      }
    }
  }

  void _drawStarPattern(
    Canvas canvas,
    double x,
    double y,
    double size,
    Paint paint,
  ) {
    final path = Path();
    final center = Offset(x + size / 2, y + size / 2);
    final radius = size / 2;

    // Draw octagon
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Draw inner star
    final innerPath = Path();
    final innerRadius = radius * 0.6;

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + math.pi / 8;
      final px = center.dx + innerRadius * math.cos(angle);
      final py = center.dy + innerRadius * math.sin(angle);

      if (i == 0) {
        innerPath.moveTo(px, py);
      } else {
        innerPath.lineTo(px, py);
      }
    }
    innerPath.close();
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
