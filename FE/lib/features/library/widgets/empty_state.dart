import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';

class EmptyState extends StatelessWidget {
  final SettingsViewModel settingsVM;
  final bool isFiltered;
  final VoidCallback onClearFilters;
  final VoidCallback onImport;

  const EmptyState({
    super.key,
    required this.settingsVM,
    required this.isFiltered,
    required this.onClearFilters,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: settingsVM,
      builder: (context, _) {
        final strings = settingsVM.strings;
        final icon = isFiltered ? Icons.search_off : Icons.library_books;
        final title = isFiltered ? strings.noResultsFound : strings.noPapersYet;
        final subtitle = isFiltered ? strings.tryAdjustingFilters : strings.importPaperToStart;
        final actionLabel = isFiltered ? strings.clearFilters : strings.importPaper;
        final action = isFiltered ? onClearFilters : onImport;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: colors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}
