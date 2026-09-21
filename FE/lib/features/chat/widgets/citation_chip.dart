import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';

class CitationChip extends StatelessWidget {
  final String label;
  final String excerpt;
  final VoidCallback onTap;
  final bool isVi;

  const CitationChip({
    super.key,
    required this.label,
    required this.excerpt,
    required this.onTap,
    this.isVi = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    
    // Format label based on active language
    String displayLabel = label;
    final numMatch = RegExp(r'\d+').firstMatch(label);
    if (numMatch != null) {
      final pageNum = numMatch.group(0);
      displayLabel = isVi ? 'tr. $pageNum' : 'p. $pageNum';
    }

    return Tooltip(
      message: excerpt,
      padding: const EdgeInsets.all(10),
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colors.selectionBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            displayLabel,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
