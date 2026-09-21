import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';

class StarterPrompts extends StatelessWidget {
  final AppStrings strings;
  final ValueChanged<String> onPromptSelected;

  const StarterPrompts({
    super.key,
    required this.strings,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology, size: 48, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            strings.starterPromptTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildPrompt(context, strings.promptSummarize),
                _buildPrompt(context, strings.promptContribution),
                _buildPrompt(context, strings.promptMethodology),
                _buildPrompt(context, strings.promptFindings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(BuildContext context, String text) {
    final colors = AppColorsExtension.of(context);
    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          color: colors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: () => onPromptSelected(text),
      backgroundColor: colors.surfaceElevated,
      side: BorderSide(color: colors.divider),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
