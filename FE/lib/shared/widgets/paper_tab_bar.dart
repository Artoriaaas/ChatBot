import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/paper.dart';

class PaperTabBar extends StatelessWidget {
  final SettingsViewModel settingsVM;
  final List<Paper> openPapers;
  final Paper? activePaper;
  final ValueChanged<Paper> onSelectTab;
  final ValueChanged<Paper> onCloseTab;
  final VoidCallback? onAddTab;

  final bool isSidebarCollapsed;
  final VoidCallback? onToggleSidebar;

  const PaperTabBar({
    super.key,
    required this.settingsVM,
    required this.openPapers,
    required this.activePaper,
    required this.onSelectTab,
    required this.onCloseTab,
    this.onAddTab,
    this.isSidebarCollapsed = false,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: settingsVM,
      builder: (context, _) {
        final strings = settingsVM.strings;

        return Container(
          height: 38,
          decoration: BoxDecoration(
            color: colors.sidebarBackground,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              if (isSidebarCollapsed && onToggleSidebar != null)
                Tooltip(
                  message: strings.toggleSidebar,
                  child: InkWell(
                    onTap: onToggleSidebar,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(Icons.view_sidebar_outlined, size: 18, color: colors.textSecondary),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: openPapers.map((paper) {
                      final isActive = activePaper?.id == paper.id;
                      return _TabItem(
                        paper: paper,
                        isActive: isActive,
                        onTap: () => onSelectTab(paper),
                        onClose: () => onCloseTab(paper),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (onAddTab != null)
                Tooltip(
                  message: strings.openNewPaper,
                  child: InkWell(
                    onTap: onAddTab,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(Icons.add, size: 18, color: colors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TabItem extends StatefulWidget {
  final Paper paper;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.paper,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.paper.title,
          waitDuration: const Duration(milliseconds: 500),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 38,
            constraints: const BoxConstraints(maxWidth: 220, minWidth: 120),
            padding: const EdgeInsets.only(left: 10, right: 6),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? colors.surface
                  : (_isHovered ? colors.surfaceElevated.withValues(alpha: 0.6) : Colors.transparent),
              border: Border(
                right: BorderSide(color: colors.divider, width: 0.8),
                top: widget.isActive ? BorderSide(color: colors.primary, width: 2) : BorderSide.none,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 15,
                  color: widget.isActive ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.paper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                      color: widget.isActive ? colors.textPrimary : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: widget.onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(
                        Icons.close,
                        size: 13,
                        color: widget.isActive || _isHovered
                            ? colors.textSecondary
                            : colors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

