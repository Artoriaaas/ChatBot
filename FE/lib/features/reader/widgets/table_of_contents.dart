import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/paper.dart';

class TableOfContents extends StatelessWidget {
  final SettingsViewModel settingsVM;
  final Paper paper;
  final int currentPage;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onClose;

  const TableOfContents({
    super.key,
    required this.settingsVM,
    required this.paper,
    required this.currentPage,
    required this.onPageSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return ListenableBuilder(
      listenable: settingsVM,
      builder: (context, _) {
        final strings = settingsVM.strings;

        return Container(
          color: colors.sidebarBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.sidebarBackground,
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_list_bulleted, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      strings.tocHeader,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
                      onPressed: onClose,
                      tooltip: strings.closeToc,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),

              // Sections List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  itemCount: paper.pages.length,
                  itemBuilder: (context, index) {
                    final page = paper.pages[index];
                    final isSelected = index == currentPage;

                    return InkWell(
                      onTap: () => onPageSelected(index),
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.selectionBackground : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    page.sectionTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                                      color: isSelected ? colors.primary : colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${strings.pageAbbr} ${page.pageNumber}',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: isSelected ? colors.primary : colors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
