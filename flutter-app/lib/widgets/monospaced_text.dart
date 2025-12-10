import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Text widget with monospaced digits (tabular figures)
///
/// Used for numeric displays to ensure proper alignment
/// Matches Swift app's .monospacedDigit() modifier
class MonospacedText extends StatelessWidget {
  final String text;
  final TextStyle? style; // Accept full style or individual properties
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign textAlign;

  const MonospacedText(
    this.text, {
    super.key,
    this.style,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    // If style is provided, use it as base and merge individual properties
    final baseStyle = style ?? const TextStyle();
    final effectiveFontSize = fontSize ?? baseStyle.fontSize ?? 36;
    final effectiveFontWeight = fontWeight ?? baseStyle.fontWeight ?? FontWeight.bold;
    final effectiveColor = color ?? baseStyle.color ?? AppColors.textPrimary;

    return Text(
      text,
      style: TextStyle(
        fontSize: effectiveFontSize,
        fontWeight: effectiveFontWeight,
        color: effectiveColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      textAlign: textAlign,
    );
  }
}
