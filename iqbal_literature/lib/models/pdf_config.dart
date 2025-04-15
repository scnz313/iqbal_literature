import 'package:flutter/material.dart';

/// Configuration model for PDF export with comprehensive styling options
class PdfConfig {
  /// Title of the PDF document
  final String title;

  /// Main content (typically poem text)
  final String content;

  /// Optional author name
  final String? author;

  /// Filename for the generated PDF (without extension)
  final String filename;

  /// Background color for content area
  final Color backgroundColor;

  /// Text color for content
  final Color textColor;

  /// Optional custom font size (null means auto-sizing)
  final double? fontSize;

  /// Whether the PDF should use landscape orientation
  final bool landscape;

  /// Optional watermark text
  final String? watermarkText;

  /// Whether to add page numbers when multiple pages are present
  final bool addPageNumbers;

  /// Whether to group stanzas to prevent mid-stanza page breaks
  final bool groupStanzas;

  /// Whether to auto-detect and handle mixed language content
  final bool enableMixedLanguageSupport;

  /// Whether to enable dynamic text sizing based on content length
  final bool enableDynamicTextSizing;

  /// Optional language hint for primary content language
  /// (null for auto-detection)
  final String? primaryLanguage;

  PdfConfig({
    required this.title,
    required this.content,
    required this.filename,
    this.author,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.fontSize,
    this.landscape = false,
    this.watermarkText,
    this.addPageNumbers = true,
    this.groupStanzas = true,
    this.enableMixedLanguageSupport = true,
    this.enableDynamicTextSizing = true,
    this.primaryLanguage,
  });

  /// Create a copy of this config with some properties changed
  PdfConfig copyWith({
    String? title,
    String? content,
    String? author,
    String? filename,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    bool? landscape,
    String? watermarkText,
    bool? addPageNumbers,
    bool? groupStanzas,
    bool? enableMixedLanguageSupport,
    bool? enableDynamicTextSizing,
    String? primaryLanguage,
  }) {
    return PdfConfig(
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      filename: filename ?? this.filename,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      landscape: landscape ?? this.landscape,
      watermarkText: watermarkText ?? this.watermarkText,
      addPageNumbers: addPageNumbers ?? this.addPageNumbers,
      groupStanzas: groupStanzas ?? this.groupStanzas,
      enableMixedLanguageSupport:
          enableMixedLanguageSupport ?? this.enableMixedLanguageSupport,
      enableDynamicTextSizing:
          enableDynamicTextSizing ?? this.enableDynamicTextSizing,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
    );
  }
}
