import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';

class SelectionMenu extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback onExplain;
  final VoidCallback onSummarize;
  final VoidCallback onAskAi;
  final VoidCallback onHighlight;
  final VoidCallback onAddNote;

  const SelectionMenu({
    super.key,
    required this.strings,
    required this.onExplain,
    required this.onSummarize,
    required this.onAskAi,
    required this.onHighlight,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(6),
      color: colors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(context, Icons.chat_bubble_outline, strings.askAi, onAskAi),
            _buildOption(context, Icons.lightbulb_outline, strings.explain, onExplain),
            _buildOption(context, Icons.short_text, strings.summarize, onSummarize),
            _buildOption(context, Icons.note_add_outlined, strings.addNoteOption, onAddNote),
            _buildOption(
              context,
              Icons.border_color_outlined,
              strings.highlight,
              onHighlight,
              accentColor: colors.onHighlight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? accentColor,
  }) {
    final colors = AppColorsExtension.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor ?? colors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
