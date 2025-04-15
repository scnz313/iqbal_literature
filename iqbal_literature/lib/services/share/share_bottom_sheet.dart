import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/poems/models/poem.dart';
import 'share_service.dart';
import 'pdf_creator.dart';

class ShareBottomSheet extends StatelessWidget {
  final Poem poem;
  const ShareBottomSheet({super.key, required this.poem});

  static void show(BuildContext context, Poem poem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Increased for more options
        minChildSize: 0.2,
        maxChildSize: 0.85, // Increased for more options
        builder: (_, controller) => _ShareBottomSheetContent(
          poem: poem,
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ShareBottomSheetContent(poem: poem);
  }
}

class _ShareBottomSheetContent extends StatefulWidget {
  final Poem poem;
  final ScrollController? scrollController;

  const _ShareBottomSheetContent({
    required this.poem,
    this.scrollController,
  });

  @override
  State<_ShareBottomSheetContent> createState() =>
      _ShareBottomSheetContentState();
}

class _ShareBottomSheetContentState extends State<_ShareBottomSheetContent> {
  String? selectedBackground;
  Color selectedColor = Colors.white; // Initialize with default value
  Color textColor = Colors.black; // Initialize with default value
  double fontSize = 18.0;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Use post frame callback to update colors based on theme after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      setState(() {
        selectedColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        textColor = isDark ? Colors.white : Colors.black;
      });
    });
  }

  // Custom error handling
  void _handleError(Object e) {
    setState(() {
      isLoading = false;
      errorMessage = e.toString();
    });

    Get.snackbar(
      'Error',
      'Failed to share: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  final List<String?> backgroundOptions = [
    null, // No background
    'assets/images/notebook_lines.png',
    // Comment out missing background files and add fallbacks
    // 'assets/images/backgrounds/paper_texture_1.png',
    // 'assets/images/backgrounds/paper_texture_2.png',
    // 'assets/images/backgrounds/geometric_pattern_1.png',
    // 'assets/images/backgrounds/calligraphy_pattern_1.png',
    // 'assets/images/backgrounds/islamic_pattern_1.png',
    // 'assets/images/backgrounds/gradient_1.png',
  ];

  final List<Color> colorOptions = [
    Colors.white,
    Colors.grey.shade100,
    Colors.amber.shade50,
    Colors.blue.shade50,
    Colors.green.shade50,
    Colors.pink.shade50,
    Colors.purple.shade50,
    const Color(0xFF2C2C2C),
    const Color(0xFF1F1F1F),
    const Color(0xFF3A3A3A),
    Colors.grey.shade800,
    const Color(0xFF253238),
  ];

  Widget _buildPreviewWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool needsDarkText = selectedColor.computeLuminance() > 0.5;
    Color adaptiveTextColor = needsDarkText ? Colors.black : Colors.white;

    // Use MediaQuery to get fixed dimensions - not affected by font size
    final screenWidth = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            // Fixed height that doesn't grow with font size
            maxHeight: screenWidth * 0.8,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selectedColor,
            image: selectedBackground != null && selectedBackground!.isNotEmpty
                ? DecorationImage(
                    image: AssetImage(selectedBackground!),
                    fit: BoxFit.cover,
                    opacity: 0.3,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DefaultTextStyle(
            // Set default text style that won't affect other widgets
            style: Theme.of(context).textTheme.bodyMedium!,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.poem.title,
                  style: TextStyle(
                    fontFamily: 'JameelNooriNastaleeq',
                    fontSize: fontSize + 6, // Larger font for title
                    height: 2,
                    fontWeight: FontWeight.bold,
                    color: adaptiveTextColor,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      widget.poem.cleanData,
                      style: TextStyle(
                        fontFamily: 'JameelNooriNastaleeq',
                        fontSize: fontSize,
                        height: 2,
                        color: adaptiveTextColor,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled || isLoading ? null : onTap,
      child: Opacity(
        opacity: isDisabled || isLoading ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Background',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: backgroundOptions.map((bg) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBackground = bg;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: bg != null
                            ? DecorationImage(
                                image: AssetImage(bg),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // If image fails to load, quietly use fallback
                                  debugPrint(
                                      'Error loading background image: $bg');
                                  setState(() {
                                    // Remove this bg from options if it fails
                                    if (selectedBackground == bg) {
                                      selectedBackground = null;
                                    }
                                  });
                                },
                              )
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedBackground == bg
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: selectedBackground == bg ? 2 : 1,
                        ),
                      ),
                      child:
                          bg == null ? const Center(child: Text('None')) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use a filtered list of colors based on the theme mode
    final visibleColors = colorOptions.where((color) {
      // In dark mode, only show dark-friendly colors (darker colors)
      // In light mode, only show light-friendly colors (lighter colors)
      final isLightColor = color.computeLuminance() > 0.5;
      return isDark ? !isLightColor : isLightColor;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Background Color',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: visibleColors.map((color) {
                final isSelected = selectedColor == color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font Size',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: fontSize > 14.0
                    ? () {
                        setState(() {
                          fontSize -= 2.0;
                        });
                      }
                    : null,
              ),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 14.0,
                  max: 26.0,
                  divisions: 6,
                  label: fontSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      fontSize = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: fontSize < 26.0
                    ? () {
                        setState(() {
                          fontSize += 2.0;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleShareError(BuildContext context, dynamic error) {
    debugPrint('❌ Share error: $error');
    Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().contains('permission')
              ? 'Please grant storage permission in app settings'
              : 'Failed to share: ${error.toString()}',
        ),
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

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing to share...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: widget.scrollController,
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Share Poem',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Preview
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16),
                    child: _buildPreviewWidget(),
                  ),

                  const Divider(height: 32),

                  // Error message if any
                  if (errorMessage != null && errorMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  // Customization options
                  _buildBackgroundSelector(),
                  _buildColorSelector(),
                  _buildFontSizeSelector(),

                  const Divider(height: 32),

                  // Share options
                  _buildShareOption(
                    context: context,
                    icon: Icons.text_fields,
                    title: 'Share as Text',
                    subtitle: 'Share poem text to other apps',
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        await ShareService.shareAsText(
                            widget.poem.title, widget.poem.cleanData);
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        _handleError(e);
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                  _buildShareOption(
                    context: context,
                    icon: Icons.image,
                    title: 'Share as Image',
                    subtitle: 'Create and share a beautiful image',
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        // First show loading dialog
                        _showLoadingDialog(context);

                        // Create a GlobalKey for the RepaintBoundary
                        final renderKey = GlobalKey();

                        // Build the widget that will be captured
                        final captureWidget = RepaintBoundary(
                          key: renderKey,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: selectedColor,
                                image: selectedBackground != null &&
                                        selectedBackground!.isNotEmpty
                                    ? DecorationImage(
                                        image: AssetImage(selectedBackground!),
                                        fit: BoxFit.cover,
                                        opacity: 0.3,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.poem.title,
                                    style: TextStyle(
                                      fontFamily: 'JameelNooriNastaleeq',
                                      fontSize: fontSize + 6,
                                      height: 2,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          selectedColor.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    widget.poem.cleanData,
                                    style: TextStyle(
                                      fontFamily: 'JameelNooriNastaleeq',
                                      fontSize: fontSize,
                                      height: 2,
                                      color:
                                          selectedColor.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Shared via Iqbal Literature',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: (selectedColor.computeLuminance() >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white)
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        // Insert widget into an overlay to render it
                        final overlayEntry = OverlayEntry(
                          builder: (context) => Positioned(
                            left: -2000, // Position offscreen
                            top: -2000,
                            child: captureWidget,
                          ),
                        );

                        // Add to overlay and wait for it to be built
                        Overlay.of(context).insert(overlayEntry);

                        // Wait for the widget to be built
                        await Future.delayed(const Duration(milliseconds: 100));

                        if (context.mounted) {
                          // Share the image using our improved service
                          await ShareService.shareAsImage(
                            context,
                            captureWidget,
                            'poem_${widget.poem.id}',
                            backgroundColor: selectedColor,
                            backgroundImage: selectedBackground != null &&
                                    selectedBackground!.isNotEmpty
                                ? selectedBackground
                                : null,
                            containerWidth:
                                MediaQuery.of(context).size.width * 0.9,
                          );

                          // Remove overlay entry
                          overlayEntry.remove();

                          // Close dialogs
                          if (mounted) {
                            Navigator.pop(context); // Close loading dialog
                            Navigator.pop(context); // Close bottom sheet
                          }
                        }
                      } catch (e) {
                        // Close loading dialog if open
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        _handleError(e);
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                  _buildShareOption(
                    context: context,
                    icon: Icons.picture_as_pdf,
                    title: 'Share as PDF',
                    subtitle: 'Create a simple PDF document',
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final poemTitle = widget.poem.title;
                        final poemContent = widget.poem.cleanData;
                        final filenameBase = 'poem_${widget.poem.id}';

                        // Use the new PDF generator
                        final success = await IqbalPdfGenerator.sharePoemPdf(
                          context,
                          poemTitle,
                          poemContent,
                          filenameBase,
                        );

                        // Only close bottom sheet if sharing succeeded
                        if (success && mounted) {
                          Navigator.pop(context); // Close bottom sheet
                        }
                      } catch (e) {
                        debugPrint('❌ Error during PDF share flow: $e');
                        _handleError(e);
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
