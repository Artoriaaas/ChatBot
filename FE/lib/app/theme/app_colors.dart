import 'package:flutter/material.dart';

/// Contrast adjustments note:
/// Checked WCAG AA contrast (4.5:1) for the following pairs:
/// - textSecondary on surface (both themes)
/// - onHighlight on highlightBackground (both themes)
/// - onSelection on selectionBackground (both themes)
/// All original pairs meet the 4.5:1 requirement, so no adjustments were needed.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color appBackground;
  final Color sidebarBackground;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color primary;
  final Color onPrimary;
  final Color selectionBackground;
  final Color onSelection;
  final Color highlightBackground;
  final Color onHighlight;
  final Color error;

  const AppColorsExtension({
    required this.appBackground,
    required this.sidebarBackground,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.primary,
    required this.onPrimary,
    required this.selectionBackground,
    required this.onSelection,
    required this.highlightBackground,
    required this.onHighlight,
    required this.error,
  });

  static const light = AppColorsExtension(
    appBackground: Color(0xFFF5F4F0),
    sidebarBackground: Color(0xFFF0EFEB),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFBFBFA),
    textPrimary: Color(0xFF1E242B),
    textSecondary: Color(0xFF5A6578),
    divider: Color(0xFFE2E4DF),
    primary: Color(0xFF1B365D),
    onPrimary: Color(0xFFFFFFFF),
    selectionBackground: Color(0xFFE6EEF8),
    onSelection: Color(0xFF1B365D),
    highlightBackground: Color(0xFFFEF3C7),
    onHighlight: Color(0xFF92400E),
    error: Color(0xFFDC2626),
  );

  static const dark = AppColorsExtension(
    appBackground: Color(0xFF12161E),
    sidebarBackground: Color(0xFF181D26),
    surface: Color(0xFF1E2430),
    surfaceElevated: Color(0xFF262E3D),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    divider: Color(0xFF2D3748),
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF0F172A),
    selectionBackground: Color(0xFF1E3A8A),
    onSelection: Color(0xFFDBEAFE),
    highlightBackground: Color(0xFF78350F),
    onHighlight: Color(0xFFFDE68A),
    error: Color(0xFFF87171),
  );

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? appBackground,
    Color? sidebarBackground,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? primary,
    Color? onPrimary,
    Color? selectionBackground,
    Color? onSelection,
    Color? highlightBackground,
    Color? onHighlight,
    Color? error,
  }) {
    return AppColorsExtension(
      appBackground: appBackground ?? this.appBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      selectionBackground: selectionBackground ?? this.selectionBackground,
      onSelection: onSelection ?? this.onSelection,
      highlightBackground: highlightBackground ?? this.highlightBackground,
      onHighlight: onHighlight ?? this.onHighlight,
      error: error ?? this.error,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      selectionBackground: Color.lerp(selectionBackground, other.selectionBackground, t)!,
      onSelection: Color.lerp(onSelection, other.onSelection, t)!,
      highlightBackground: Color.lerp(highlightBackground, other.highlightBackground, t)!,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }

  static AppColorsExtension of(BuildContext context) {
    return Theme.of(context).extension<AppColorsExtension>()!;
  }
}
