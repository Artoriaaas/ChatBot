import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _inter({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  static TextStyle get heading1 => _inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get heading2 => _inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get heading3 => _inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get subtitle => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get body => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyLarge => _inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get caption => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get button => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.0,
      ).copyWith(letterSpacing: 0.2);

  static TextStyle get code => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextTheme textTheme({Color? bodyColor}) => TextTheme(
        headlineLarge: heading1.copyWith(color: bodyColor),
        headlineMedium: heading2.copyWith(color: bodyColor),
        headlineSmall: heading3.copyWith(color: bodyColor),
        titleMedium: subtitle.copyWith(color: bodyColor),
        bodyMedium: body.copyWith(color: bodyColor),
        bodyLarge: bodyLarge.copyWith(color: bodyColor),
        bodySmall: caption.copyWith(color: bodyColor),
        labelLarge: button.copyWith(color: bodyColor),
      );
}
