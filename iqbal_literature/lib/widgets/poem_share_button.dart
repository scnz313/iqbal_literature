import 'package:flutter/material.dart';
import '../services/share/pdf_creator.dart';

/// A specialized button for sharing poems as PDFs with advanced options
class PoemShareButton extends StatelessWidget {
  final String title;
  final String content;
  final String? author;
  final IconData? icon;
  final String? label;

  const PoemShareButton({
    super.key,
    required this.title,
    required this.content,
    this.author,
    this.icon = Icons.picture_as_pdf,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return label != null
        ? ElevatedButton.icon(
            icon: Icon(icon),
            label: Text(label!),
            onPressed: () => _openPdfOptions(context),
          )
        : IconButton(
            icon: Icon(icon),
            tooltip: 'Export as PDF',
            onPressed: () => _openPdfOptions(context),
          );
  }

  // Share the poem as PDF
  Future<void> _openPdfOptions(BuildContext context) async {
    try {
      final filenameBase = 'poem_${title.hashCode}';

      // Use the new streamlined PDF generator
      await IqbalPdfGenerator.sharePoemPdf(
        context,
        title,
        content,
        filenameBase,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
