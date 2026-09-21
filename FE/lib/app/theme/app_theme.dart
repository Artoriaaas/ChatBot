import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colors = AppColorsExtension.light;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.appBackground,
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.error,
        outline: colors.divider,
      ),
      textTheme: AppTypography.textTheme(bodyColor: colors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.sidebarBackground,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.divider),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(0, 36),
        ),
      ),
      iconTheme: IconThemeData(
        size: 20,
        color: colors.textSecondary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: AppTypography.heading3.copyWith(color: colors.textPrimary),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.sidebarBackground,
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.textSecondary),
        indicatorColor: colors.selectionBackground,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.textSecondary.withValues(alpha: 0.3)),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
      ),
      splashFactory: NoSplash.splashFactory, // Used NoSplash for desktop feel
      useMaterial3: true,
      focusColor: colors.primary.withValues(alpha: 0.12),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colors.selectionBackground,
        cursorColor: colors.primary,
        selectionHandleColor: colors.primary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.selectionBackground,
        labelStyle: AppTypography.body,
        padding: EdgeInsets.zero,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppColorsExtension.light,
      ],
    );
  }

  static ThemeData get dark {
    final colors = AppColorsExtension.dark;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.appBackground,
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.error,
        outline: colors.divider,
      ),
      textTheme: AppTypography.textTheme(bodyColor: colors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.sidebarBackground,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.divider),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(0, 36),
        ),
      ),
      iconTheme: IconThemeData(
        size: 20,
        color: colors.textSecondary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.black87),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: AppTypography.heading3.copyWith(color: colors.textPrimary),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.sidebarBackground,
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.textSecondary),
        indicatorColor: colors.selectionBackground,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.textSecondary.withValues(alpha: 0.3)),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
      ),
      splashFactory: NoSplash.splashFactory, // Used NoSplash for desktop feel
      useMaterial3: true,
      focusColor: colors.primary.withValues(alpha: 0.12),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colors.selectionBackground,
        cursorColor: colors.primary,
        selectionHandleColor: colors.primary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.selectionBackground,
        labelStyle: AppTypography.body,
        padding: EdgeInsets.zero,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppColorsExtension.dark,
      ],
    );
  }
}
