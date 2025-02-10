import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/font_controller.dart';

class ScaledText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;

  const ScaledText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return GetX<FontController>(
      builder: (controller) {
        final baseSize = style?.fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
        final scaledStyle = style?.copyWith(
          fontSize: baseSize * controller.scaleFactor.value,
        );
        
        return Text(
          text,
          style: scaledStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
