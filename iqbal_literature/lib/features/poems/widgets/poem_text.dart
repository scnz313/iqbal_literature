import 'package:flutter/material.dart';
import '../../../core/widgets/scaled_text.dart';
import '../../../core/mixins/font_scale_mixin.dart';

class PoemText extends StatelessWidget with FontScaleMixin {
  final String text;
  final String languageCode;

  const PoemText({
    super.key,
    required this.text,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      height: 1.8, // Add line height for poetry
      letterSpacing: languageCode == 'ur' ? 1.2 : 0.5,
    );
    
    return ScaledText(
      text,
      style: baseStyle,
      textDirection: languageCode == 'ur' ? TextDirection.rtl : TextDirection.ltr,
      textAlign: languageCode == 'ur' ? TextAlign.right : TextAlign.left,
    );
  }
}
