import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/auth/auth_view_model.dart';
import 'package:paper_chat/features/projects/projects_view_model.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/models/project.dart';

class AppSidebar extends StatefulWidget {
  final SettingsViewModel settingsVM;
  final ProjectsViewModel? projectsVM;
  final AuthViewModel? authVM;
  final int selectedNavIndex; // 0=Library, 1=Recent, 2=Notes, 3=Settings
  final ValueChanged<int> onSelectNav;
  final List<Paper> openPapers;
  final Paper? activePaper;
  final Project? activeProject;
  final ValueChanged<Paper> onSelectPaper;
  final ValueChanged<Project>? onSelectProject;
  final ValueChanged<Project>? onAddPaperToProject;
  final ValueChanged<Project>? onEditProject;
  final ValueChanged<Project>? onNewProjectChat;
  final VoidCallback? onCreateProject;
  final VoidCallback? onToggleCollapse;
  final ValueChanged<String>? onSearch;

  const AppSidebar({
    super.key,
    required this.settingsVM,
    this.projectsVM,
    this.authVM,
    required this.selectedNavIndex,
    required this.onSelectNav,
    required this.openPapers,
    required this.activePaper,
    this.activeProject,
    required this.onSelectPaper,
    this.onSelectProject,
    this.onAddPaperToProject,
    this.onEditProject,
    this.onNewProjectChat,
    this.onCreateProject,
    this.onToggleCollapse,
    this.onSearch,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedProjectIds = {};

  @override
  void initState() {
    super.initState();
    // Expand first project by default if available
    if (widget.projectsVM != null && widget.projectsVM!.projects.isNotEmpty) {
      _expandedProjectIds.add(widget.projectsVM!.projects.first.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleProjectExpand(String projectId) {
    setState(() {
      if (_expandedProjectIds.contains(projectId)) {
        _expandedProjectIds.remove(projectId);
      } else {
        _expandedProjectIds.add(projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.settingsVM,
        if (widget.projectsVM != null) widget.projectsVM!,
      ]),
      builder: (context, _) {
        final strings = widget.settingsVM.strings;
        final projects = widget.projectsVM?.projects ?? [];

        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: colors.sidebarBackground,
            border: Border(right: BorderSide(color: colors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header / Logo
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.appTitle,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onToggleCollapse != null)
                      Tooltip(
                        message: strings.toggleSidebar,
                        child: IconButton(
                          icon: Icon(Icons.view_sidebar_outlined, size: 16, color: colors.textSecondary),
                          onPressed: widget.onToggleCollapse,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: SizedBox(
                  height: 30,
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearch,
                    style: AppTypography.caption.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: strings.searchDocuments,
                      hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.7)),
                      prefixIcon: Icon(Icons.search, size: 14, color: colors.textSecondary),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: colors.surface,
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
              ),
              const SizedBox(height: 8),

              // Main Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  children: [
                    _SidebarNavItem(
                      icon: Icons.grid_view_rounded,
                      label: strings.library,
                      isSelected: widget.activePaper == null && widget.activeProject == null && widget.selectedNavIndex == 0,
                      onTap: () => widget.onSelectNav(0),
                    ),
                    _SidebarNavItem(
                      icon: Icons.history_rounded,
                      label: strings.recent,
                      isSelected: widget.activePaper == null && widget.activeProject == null && widget.selectedNavIndex == 1,
                      onTap: () => widget.onSelectNav(1),
                    ),
                    _SidebarNavItem(
                      icon: Icons.description_outlined,
                      label: strings.notes,
                      isSelected: widget.activePaper == null && widget.activeProject == null && widget.selectedNavIndex == 2,
                      onTap: () => widget.onSelectNav(2),
                    ),
                    const SizedBox(height: 16),

                    // Section: DỰ ÁN (PROJECTS TREE DROPDOWN)
                    _SectionHeader(
                      title: strings.projectsSection,
                      onAddTap: widget.onCreateProject,
                      addTooltip: strings.createProject,
                    ),
                    if (projects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          strings.noProjectsYet,
                          style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7)),
                        ),
                      )
                    else
                      ...projects.map((proj) {
                        final isExpanded = _expandedProjectIds.contains(proj.id);
                        final attachedPapers = widget.projectsVM?.getPapersForProject(proj) ?? [];
                        final isProjectSelected = widget.activeProject?.id == proj.id;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Header Item with Expand Arrow & Action buttons
                            _ProjectHeaderItem(
                              project: proj,
                              attachedPapers: attachedPapers,
                              isExpanded: isExpanded,
                              isSelected: isProjectSelected && widget.activePaper == null,
                              onToggleExpand: () => _toggleProjectExpand(proj.id),
                              onTapProject: () {
                                widget.onSelectProject?.call(proj);
                                if (!isExpanded) {
                                  _toggleProjectExpand(proj.id);
                                }
                              },
                              onEditProject: () => widget.onEditProject?.call(proj),
                              onNewChat: () => widget.onNewProjectChat?.call(proj),
                            ),

                            // Project Children Dropdown List
                            if (isExpanded) ...[
                              if (attachedPapers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 28, top: 2, bottom: 6),
                                  child: Row(
                                    children: [
                                      Text(
                                        '(Dự án trống)',
                                        style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.6), fontStyle: FontStyle.italic),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => widget.onAddPaperToProject?.call(proj),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Text(
                                            '+ Thêm',
                                            style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...attachedPapers.map((paper) {
                                  final isPaperActive = widget.activePaper?.id == paper.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 24),
                                    child: _SidebarNavItem(
                                      icon: Icons.article_outlined,
                                      label: paper.title,
                                      isSelected: isPaperActive,
                                      isSubItem: true,
                                      onTap: () {
                                        widget.onSelectProject?.call(proj);
                                        widget.onSelectPaper(paper);
                                      },
                                    ),
                                  );
                                }),
                            ],
                          ],
                        );
                      }),
                    const SizedBox(height: 16),


                    // Section: ĐANG MỞ (Currently Open Papers)
                    if (widget.openPapers.isNotEmpty) ...[
                      _SectionHeader(title: strings.currentlyOpen),
                      ...widget.openPapers.map((paper) {
                        final isPaperActive = widget.activePaper?.id == paper.id;
                        return _SidebarNavItem(
                          icon: Icons.article_outlined,
                          label: paper.title,
                          isSelected: isPaperActive,
                          onTap: () => widget.onSelectPaper(paper),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              // Footer: Settings & User Profile
              Divider(height: 1, color: colors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    _SidebarNavItem(
                      icon: Icons.settings_outlined,
                      label: strings.settings,
                      isSelected: widget.selectedNavIndex == 3 && widget.activePaper == null && widget.activeProject == null,
                      onTap: () => widget.onSelectNav(3),
                    ),
                    if (widget.authVM?.currentUser != null) ...[
                      Builder(
                        builder: (context) {
                          final user = widget.authVM!.currentUser!;
                          final avatarChar = user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : 'U';
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: colors.primary,
                                    child: Text(
                                      avatarChar,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.onPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user.name,
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.textPrimary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colors.textSecondary.withValues(alpha: 0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.logout_rounded, size: 16, color: colors.textSecondary),
                                    tooltip: strings.logout,
                                    onPressed: () async => await widget.authVM?.logout(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectHeaderItem extends StatefulWidget {
  final Project project;
  final List<Paper> attachedPapers;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onToggleExpand;
  final VoidCallback onTapProject;
  final VoidCallback onEditProject;
  final VoidCallback onNewChat;

  const _ProjectHeaderItem({
    required this.project,
    required this.attachedPapers,
    required this.isExpanded,
    required this.isSelected,
    required this.onToggleExpand,
    required this.onTapProject,
    required this.onEditProject,
    required this.onNewChat,
  });

  @override
  State<_ProjectHeaderItem> createState() => _ProjectHeaderItemState();
}

class _ProjectHeaderItemState extends State<_ProjectHeaderItem> {
  bool _isHovered = false;

  void _showFlyout(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        final colors = AppColorsExtension.of(ctx);

        return Stack(
          children: [
            // Dismiss background tap
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            // Flyout Card anchored to project item
            Positioned(
              left: offset.dx + 180,
              top: offset.dy - 10,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Folder + Title + Pin icon
                      Padding(
                        padding: const EdgeInsets.only(left: 14, right: 12, top: 12, bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.folder_outlined, size: 17, color: colors.textPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.project.title,
                                style: AppTypography.subtitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.push_pin_outlined, size: 15, color: colors.textSecondary),
                          ],
                        ),
                      ),

                      // Task / Doc Count Row
                      Padding(
                        padding: const EdgeInsets.only(left: 14, right: 12, bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: colors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.attachedPapers.length} task${widget.attachedPapers.length == 1 ? '' : 's'}',
                              style: AppTypography.caption.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: colors.divider),

                      // Source Files list
                      if (widget.attachedPapers.isNotEmpty)
                        ...widget.attachedPapers.map((paper) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.folder_outlined, size: 15, color: colors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    paper.title,
                                    style: AppTypography.caption.copyWith(
                                      color: colors.textPrimary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      Divider(height: 1, color: colors.divider),

                      // Edit project Row
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onEditProject();
                        },
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined, size: 16, color: colors.textPrimary),
                              const SizedBox(width: 10),
                              Text(
                                'Edit project',
                                style: AppTypography.caption.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 30,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colors.selectionBackground
              : (_isHovered ? colors.surface.withValues(alpha: 0.6) : Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Expand/Collapse Arrow Button
            InkWell(
              onTap: widget.onToggleExpand,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  widget.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),

            // Project Icon & Title
            Expanded(
              child: InkWell(
                onTap: widget.onTapProject,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_special_rounded,
                      size: 15,
                      color: widget.isSelected ? colors.primary : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: widget.isSelected ? colors.primary : colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // On Hover: 3-dots Menu & New Chat Button
            if (_isHovered || widget.isSelected) ...[
              // 3-dots Button (Flyout / Edit Project)
              IconButton(
                icon: Icon(Icons.more_horiz_rounded, size: 16, color: colors.textSecondary),
                tooltip: 'Edit project',
                onPressed: () => _showFlyout(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              ),
              const SizedBox(width: 2),

              // New Project Chat Button
              IconButton(
                icon: Icon(Icons.edit_note_rounded, size: 17, color: colors.textSecondary),
                tooltip: 'Đoạn chat mới bao phủ dự án',
                onPressed: widget.onNewChat,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAddTap;
  final String? addTooltip;

  const _SectionHeader({
    required this.title,
    this.onAddTap,
    this.addTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          if (onAddTap != null)
            IconButton(
              icon: Icon(Icons.add, size: 14, color: colors.textSecondary),
              tooltip: addTooltip,
              onPressed: onAddTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isSubItem;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isSubItem = false,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.selectionBackground
                : (_isHovered ? colors.surface.withValues(alpha: 0.6) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: widget.isSubItem ? 13 : 14,
                color: widget.isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: widget.isSubItem ? 11.5 : 12,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
