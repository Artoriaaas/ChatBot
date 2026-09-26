import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/features/chat/chat_view_model.dart';
import 'package:paper_chat/features/library/library_screen.dart';
import 'package:paper_chat/features/library/library_view_model.dart';
import 'package:paper_chat/features/notes/notes_screen.dart';
import 'package:paper_chat/features/notes/notes_view_model.dart';
import 'package:paper_chat/features/projects/project_workspace_screen.dart';
import 'package:paper_chat/features/projects/projects_view_model.dart';
import 'package:paper_chat/features/projects/widgets/add_papers_dialog.dart';
import 'package:paper_chat/features/projects/widgets/create_project_dialog.dart';
import 'package:paper_chat/features/projects/widgets/edit_project_dialog.dart';
import 'package:paper_chat/features/reader/reader_screen.dart';
import 'package:paper_chat/features/reader/reader_view_model.dart';
import 'package:paper_chat/features/settings/settings_screen.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/models/project.dart';
import 'package:paper_chat/services/notes_repository.dart';
import 'package:paper_chat/shared/widgets/app_sidebar.dart';
import 'package:paper_chat/features/auth/auth_view_model.dart';
import 'package:paper_chat/shared/widgets/paper_tab_bar.dart';

class AppShell extends StatefulWidget {
  final SettingsViewModel settingsVM;
  final LibraryViewModel libraryVM;
  final ReaderViewModel readerVM;
  final ChatViewModel chatVM;
  final NotesViewModel notesVM;
  final ProjectsViewModel? projectsVM;
  final NotesRepository notesRepo;
  final AuthViewModel authVM;

  const AppShell({
    super.key,
    required this.settingsVM,
    required this.libraryVM,
    required this.readerVM,
    required this.chatVM,
    required this.notesVM,
    this.projectsVM,
    required this.notesRepo,
    required this.authVM,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedNavIndex = 0; // 0=Library, 1=Recent, 2=Notes, 3=Settings
  final List<Paper> _openPapers = [];
  Paper? _selectedPaper;
  bool _isSidebarCollapsed = false;
  bool _isProjectChatMode = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with first paper if available for immediate demo quality
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.libraryVM.papers.isNotEmpty) {
        _openPaper(widget.libraryVM.papers.first);
      }
    });
  }

  void _onSelectNav(int index) {
    setState(() {
      _selectedNavIndex = index;
      _selectedPaper = null;
      _isProjectChatMode = false;
      widget.projectsVM?.setActiveProject(null);
    });
  }

  void _onSelectProject(Project project) {
    widget.projectsVM?.setActiveProject(project);
    final attachedPapers = widget.projectsVM?.getPapersForProject(project) ?? [];
    if (attachedPapers.isNotEmpty) {
      _openPaper(attachedPapers.first);
    } else {
      _showAddPapersDialogFor(project);
    }
  }

  void _onOpenProjectChat(Project project) {
    widget.projectsVM?.setActiveProject(project);
    setState(() {
      _selectedPaper = null;
      _isProjectChatMode = true;
    });
  }

  void _showEditProjectDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => EditProjectDialog(
        strings: widget.settingsVM.strings,
        project: project,
        availablePapers: widget.libraryVM.papers,
        onSave: (newTitle, paperIds) {
          widget.projectsVM?.updateProjectDetails(project.id, newTitle, paperIds);
          setState(() {});
        },
        onDelete: () {
          widget.projectsVM?.deleteProject(project.id);
          setState(() {
            _isProjectChatMode = false;
          });
        },
      ),
    );
  }

  void _showAddPapersDialogFor(Project project) {
    widget.projectsVM?.setActiveProject(project);
    final availablePapers = widget.libraryVM.papers;

    showDialog(
      context: context,
      builder: (context) => AddPapersDialog(
        strings: widget.settingsVM.strings,
        project: project,
        availablePapers: availablePapers,
        onSave: (selectedIds) async {
          final currentIds = project.paperIds.toSet();
          for (final id in selectedIds) {
            if (!currentIds.contains(id)) {
              await widget.projectsVM?.addPaperToActiveProject(id);
            }
          }
          for (final id in currentIds) {
            if (!selectedIds.contains(id)) {
              await widget.projectsVM?.removePaperFromActiveProject(id);
            }
          }
          setState(() {});
        },
      ),
    );
  }

  void _showSelectProjectDialogForPaper(Paper paper) {
    final projects = widget.projectsVM?.projects ?? [];
    final strings = widget.settingsVM.strings;

    if (projects.isEmpty) {
      _showCreateProjectDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = AppColorsExtension.of(dialogContext);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(strings.selectProjectToAddTo, style: TextStyle(color: colors.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: 380,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final proj = projects[index];
                final isAlreadyAdded = proj.paperIds.contains(paper.id);
                return ListTile(
                  leading: Icon(
                    Icons.folder_special_rounded,
                    color: isAlreadyAdded ? colors.primary : colors.textSecondary,
                  ),
                  title: Text(
                    proj.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: isAlreadyAdded ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    isAlreadyAdded ? 'Đã có trong dự án' : '${proj.paperIds.length} tài liệu',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: isAlreadyAdded
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                      : Icon(Icons.add_circle_outline, color: colors.primary, size: 18),
                  onTap: () async {
                    if (!isAlreadyAdded) {
                      widget.projectsVM?.setActiveProject(proj);
                      await widget.projectsVM?.addPaperToActiveProject(paper.id);
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(strings.addedToProjectSuccess), duration: const Duration(seconds: 2)),
                        );
                      }
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancel, style: TextStyle(color: colors.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateProjectDialog(
        strings: widget.settingsVM.strings,
        availablePapers: widget.libraryVM.papers,
        onCreate: (title, description, paperIds) {
          widget.projectsVM?.createProject(
            title: title,
            description: description,
            initialPaperIds: paperIds,
          );
          if (paperIds.isNotEmpty) {
            final firstPaper = widget.libraryVM.papers.firstWhere(
              (p) => p.id == paperIds.first,
              orElse: () => widget.libraryVM.papers.first,
            );
            _openPaper(firstPaper);
          }
        },
      ),
    );
  }

  void _openPaper(Paper paper, [int? page]) {
    if (!_openPapers.any((p) => p.id == paper.id)) {
      _openPapers.add(paper);
    }
    _isProjectChatMode = false;
    widget.readerVM.openPaper(paper);
    widget.chatVM.setCurrentPaper(paper);
    setState(() {
      _selectedPaper = paper;
    });
    if (page != null) {
      widget.readerVM.navigateToCitation(page, null);
    }
  }

  void _closeTab(Paper paper) {
    setState(() {
      _openPapers.removeWhere((p) => p.id == paper.id);
      if (_selectedPaper?.id == paper.id) {
        if (_openPapers.isNotEmpty) {
          _selectedPaper = _openPapers.last;
          widget.readerVM.openPaper(_selectedPaper!);
          widget.chatVM.setCurrentPaper(_selectedPaper!);
        } else {
          _selectedPaper = null;
          widget.chatVM.stopStreaming();
        }
      }
    });
  }

  void _onBackFromReader() {
    widget.chatVM.stopStreaming();
    setState(() {
      _selectedPaper = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    final projectsVM = widget.projectsVM;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.settingsVM,
        widget.libraryVM,
        ?projectsVM,
      ]),
      builder: (context, _) {
        final colors = AppColorsExtension.of(context);
        final activeProject = projectsVM?.activeProject;

        // Tự động đồng bộ và loại bỏ các paper đã bị xóa khỏi danh sách đang mở
        final libraryPaperIds = widget.libraryVM.papers.map((p) => p.id).toSet();
        _openPapers.removeWhere((p) => !libraryPaperIds.contains(p.id));
        if (_selectedPaper != null && !libraryPaperIds.contains(_selectedPaper!.id)) {
          if (_openPapers.isNotEmpty) {
            _selectedPaper = _openPapers.last;
            widget.readerVM.openPaper(_selectedPaper!);
            widget.chatVM.setCurrentPaper(_selectedPaper!);
          } else {
            _selectedPaper = null;
            widget.chatVM.stopStreaming();
          }
        }

        // Build main content area based on navigation or active paper/project
        Widget mainBody;
        if (_selectedPaper != null) {
          mainBody = ReaderScreen(
            paper: _selectedPaper!,
            settingsViewModel: widget.settingsVM,
            readerViewModel: widget.readerVM,
            chatViewModel: widget.chatVM,
            notesRepository: widget.notesRepo,
            onBack: _onBackFromReader,
            isSidebarVisible: !_isSidebarCollapsed && !isNarrow,
            onToggleSidebar: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          );
        } else if (_isProjectChatMode && activeProject != null && projectsVM != null) {
          mainBody = ProjectWorkspaceScreen(
            settingsVM: widget.settingsVM,
            projectsVM: projectsVM,
            libraryVM: widget.libraryVM,
            notesRepo: widget.notesRepo,
            project: activeProject,
            onOpenPaper: (paper) {
              setState(() {
                _isProjectChatMode = false;
              });
              _openPaper(paper);
            },
          );
        } else {
          switch (_selectedNavIndex) {
            case 0:
            case 1:
              mainBody = LibraryScreen(
                settingsVM: widget.settingsVM,
                viewModel: widget.libraryVM,
                onPaperSelected: (paper) => _openPaper(paper),
                onPaperDeleted: (paper) => _closeTab(paper),
                onAddPaperToProject: (paper) => _showSelectProjectDialogForPaper(paper),
              );
              break;
            case 2:
              mainBody = NotesScreen(
                settingsVM: widget.settingsVM,
                viewModel: widget.notesVM,
                onNavigateToPaper: (paperId, page) {
                  final paper = widget.libraryVM.papers.firstWhere(
                    (p) => p.id == paperId,
                    orElse: () => widget.libraryVM.papers.first,
                  );
                  _openPaper(paper, page);
                },
              );
              break;
            case 3:
              mainBody = SettingsScreen(viewModel: widget.settingsVM);
              break;
            default:
              mainBody = LibraryScreen(
                settingsVM: widget.settingsVM,
                viewModel: widget.libraryVM,
                onPaperSelected: (paper) => _openPaper(paper),
                onPaperDeleted: (paper) => _closeTab(paper),
                onAddPaperToProject: (paper) => _showSelectProjectDialogForPaper(paper),
              );
          }
        }

        final showTabBar = _openPapers.isNotEmpty;

        return Scaffold(
          body: Row(
            children: [
              // Collapsible Left Navigation Sidebar (Desktop)
              if (!_isSidebarCollapsed && !isNarrow)
                AppSidebar(
                  settingsVM: widget.settingsVM,
                  projectsVM: projectsVM,
                  authVM: widget.authVM,
                  selectedNavIndex: _selectedNavIndex,
                  onSelectNav: _onSelectNav,
                  openPapers: _openPapers,
                  activePaper: _selectedPaper,
                  activeProject: activeProject,
                  onSelectPaper: (paper) => _openPaper(paper),
                  onSelectProject: _onSelectProject,
                  onAddPaperToProject: _showAddPapersDialogFor,
                  onEditProject: _showEditProjectDialog,
                  onNewProjectChat: _onOpenProjectChat,
                  onCreateProject: _showCreateProjectDialog,
                  onClosePaper: _closeTab,
                  onToggleCollapse: () => setState(() => _isSidebarCollapsed = true),
                  onSearch: (query) {
                    widget.libraryVM.searchQuery = query;
                    if (_selectedPaper != null) {
                      setState(() => _selectedPaper = null);
                    }
                    _isProjectChatMode = false;
                    widget.projectsVM?.setActiveProject(null);
                    _selectedNavIndex = 0;
                  },
                ),

              // Main Screen Region with Tab Bar
              Expanded(
                child: Column(
                  children: [
                    if (_isSidebarCollapsed && !isNarrow && !showTabBar)
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: colors.sidebarBackground,
                          border: Border(bottom: BorderSide(color: colors.divider)),
                        ),
                        child: Row(
                          children: [
                            Tooltip(
                              message: widget.settingsVM.strings.toggleSidebar,
                              child: InkWell(
                                onTap: () => setState(() => _isSidebarCollapsed = false),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: Icon(
                                    Icons.view_sidebar_outlined,
                                    size: 18,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 12,
                                  color: colors.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.settingsVM.strings.appTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (showTabBar)
                      PaperTabBar(
                        settingsVM: widget.settingsVM,
                        openPapers: _openPapers,
                        activePaper: _selectedPaper,
                        onSelectTab: (paper) => _openPaper(paper),
                        onCloseTab: (paper) => _closeTab(paper),
                        onAddTab: () {
                          if (widget.libraryVM.papers.isNotEmpty) {
                            _openPaper(widget.libraryVM.papers.last);
                          }
                        },
                        isSidebarCollapsed: _isSidebarCollapsed,
                        onToggleSidebar: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                      ),
                    Expanded(child: mainBody),
                  ],
                ),
              ),
            ],
          ),
          // Drawer for narrow mobile/tablet screens
          drawer: isNarrow
              ? Drawer(
                  child: AppSidebar(
                    settingsVM: widget.settingsVM,
                    projectsVM: projectsVM,
                    selectedNavIndex: _selectedNavIndex,
                    onSelectNav: (idx) {
                      _onSelectNav(idx);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    openPapers: _openPapers,
                    activePaper: _selectedPaper,
                    activeProject: activeProject,
                    onSelectPaper: (paper) {
                      _openPaper(paper);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    onSelectProject: (proj) {
                      _onSelectProject(proj);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    onAddPaperToProject: (proj) {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      _showAddPapersDialogFor(proj);
                    },
                    onEditProject: (proj) {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      _showEditProjectDialog(proj);
                    },
                    onNewProjectChat: (proj) {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      _onOpenProjectChat(proj);
                    },
                    onCreateProject: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      _showCreateProjectDialog();
                    },
                  ),
                )
              : null,
        );
      },
    );
  }
}
