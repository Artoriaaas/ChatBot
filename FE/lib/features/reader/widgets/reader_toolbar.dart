import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';

enum ReaderViewMode {
  ai,
  original,
  split,
}

class ReaderToolbar extends StatelessWidget {
  final SettingsViewModel settingsVM;
  final VoidCallback onToggleToc;
  final bool isTocOpen;
  final VoidCallback? onToggleInfo;
  final bool isInfoOpen;
  final ReaderViewMode viewMode;
  final ValueChanged<ReaderViewMode>? onViewModeChanged;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onGoToPage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final double zoomLevel;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitWidth;
  final bool isHighlightMode;
  final VoidCallback onToggleHighlightMode;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback onNextSearchResult;
  final VoidCallback onPrevSearchResult;
  final int searchResultCount;
  final int currentSearchIndex;
  final bool isContinuousMode;
  final VoidCallback onToggleContinuousMode;

  const ReaderToolbar({
    super.key,
    required this.settingsVM,
    required this.onToggleToc,
    required this.isTocOpen,
    this.onToggleInfo,
    this.isInfoOpen = false,
    this.viewMode = ReaderViewMode.ai,
    this.onViewModeChanged,
    required this.currentPage,
    required this.totalPages,
    required this.onGoToPage,
    required this.onPrevPage,
    required this.onNextPage,
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitWidth,
    required this.isHighlightMode,
    required this.onToggleHighlightMode,
    required this.searchQuery,
    required this.onSearch,
    required this.onNextSearchResult,
    required this.onPrevSearchResult,
    required this.searchResultCount,
    required this.currentSearchIndex,
    required this.isContinuousMode,
    required this.onToggleContinuousMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final pageController = TextEditingController(text: '${currentPage + 1}');

    return ListenableBuilder(
      listenable: settingsVM,
      builder: (context, _) {
        final strings = settingsVM.strings;

        return Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
              // Table of Contents Toggle Button
              Tooltip(
                message: strings.tableOfContents,
                child: TextButton.icon(
                  onPressed: onToggleToc,
                  icon: Icon(
                    Icons.format_list_bulleted,
                    size: 16,
                    color: isTocOpen ? colors.primary : colors.textSecondary,
                  ),
                  label: Text(
                    strings.tableOfContents,
                    style: AppTypography.caption.copyWith(
                      fontWeight: isTocOpen ? FontWeight.w600 : FontWeight.w400,
                      color: isTocOpen ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: isTocOpen ? colors.selectionBackground : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Paper Info Toggle Button
              if (onToggleInfo != null) ...[
                Tooltip(
                  message: strings.paperInfo,
                  child: TextButton.icon(
                    onPressed: onToggleInfo,
                    icon: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isInfoOpen ? colors.primary : colors.textSecondary,
                    ),
                    label: Text(
                      strings.paperInfo,
                      style: AppTypography.caption.copyWith(
                        fontWeight: isInfoOpen ? FontWeight.w600 : FontWeight.w400,
                        color: isInfoOpen ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: isInfoOpen ? colors.selectionBackground : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // View Mode Selector (AI vs Original PDF vs Split View)
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: colors.appBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeButton(
                      mode: ReaderViewMode.ai,
                      currentMode: viewMode,
                      icon: Icons.article_outlined,
                      label: strings.aiContent,
                      onTap: () => onViewModeChanged?.call(ReaderViewMode.ai),
                      colors: colors,
                    ),
                    _buildViewModeButton(
                      mode: ReaderViewMode.original,
                      currentMode: viewMode,
                      icon: Icons.picture_as_pdf_outlined,
                      label: strings.originalFile,
                      onTap: () => onViewModeChanged?.call(ReaderViewMode.original),
                      colors: colors,
                    ),
                    _buildViewModeButton(
                      mode: ReaderViewMode.split,
                      currentMode: viewMode,
                      icon: Icons.vertical_split_outlined,
                      label: strings.splitView,
                      onTap: () => onViewModeChanged?.call(ReaderViewMode.split),
                      colors: colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Search in PDF input box
              SizedBox(
                width: 140,
                height: 28,
                child: TextField(
                  onChanged: onSearch,
                  style: AppTypography.caption.copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: strings.searchInPdf,
                    hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.search, size: 14, color: colors.textSecondary),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: colors.appBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                ),
              ),

              if (searchQuery.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  searchResultCount > 0 ? '${currentSearchIndex + 1}/$searchResultCount' : '0/0',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 11),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 16),
                  onPressed: onPrevSearchResult,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  onPressed: onNextSearchResult,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
              ],

              const SizedBox(width: 16),

              // Page Switcher Controls (< 3 / 11 >)
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: currentPage > 0 ? onPrevPage : null,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
              Container(
                width: 32,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.appBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.divider),
                ),
                child: TextField(
                  controller: pageController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    final page = int.tryParse(val);
                    if (page != null) onGoToPage(page - 1);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '/$totalPages',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: currentPage < totalPages - 1 ? onNextPage : null,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(width: 12),
              Container(height: 16, width: 1, color: colors.divider),
              const SizedBox(width: 12),

              // Zoom Controls (- 110% +)
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: onZoomOut,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                padding: EdgeInsets.zero,
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(zoomLevel * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: onZoomIn,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                padding: EdgeInsets.zero,
              ),

              // Continuous / Paged View Mode Toggle
              Tooltip(
                message: isContinuousMode ? strings.pagedMode : strings.continuousMode,
                child: OutlinedButton.icon(
                  onPressed: onToggleContinuousMode,
                  icon: Icon(
                    isContinuousMode ? Icons.view_agenda_outlined : Icons.menu_book_outlined,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  label: Text(
                    isContinuousMode ? strings.continuousMode : strings.pagedMode,
                    style: AppTypography.caption,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: colors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Fit width button
              Tooltip(
                message: strings.fitWidth,
                child: OutlinedButton.icon(
                  onPressed: onFitWidth,
                  icon: Icon(Icons.aspect_ratio_rounded, size: 14, color: colors.textSecondary),
                  label: Text(strings.fitWidth, style: AppTypography.caption),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: colors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Highlight Tool button
              Tooltip(
                message: strings.highlight,
                child: TextButton.icon(
                  onPressed: onToggleHighlightMode,
                  icon: Icon(
                    Icons.border_color_outlined,
                    size: 14,
                    color: isHighlightMode ? colors.onHighlight : colors.textSecondary,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.highlight,
                        style: AppTypography.caption.copyWith(
                          color: isHighlightMode ? colors.onHighlight : colors.textPrimary,
                          fontWeight: isHighlightMode ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: isHighlightMode ? colors.onHighlight : colors.textSecondary,
                      ),
                    ],
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: isHighlightMode ? colors.highlightBackground : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildViewModeButton({
    required ReaderViewMode mode,
    required ReaderViewMode currentMode,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
