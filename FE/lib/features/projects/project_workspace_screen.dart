import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/chat/widgets/chat_composer.dart';
import 'package:paper_chat/features/chat/widgets/message_bubble.dart';
import 'package:paper_chat/features/library/library_view_model.dart';
import 'package:paper_chat/features/notes/widgets/minimizable_note_editor.dart';
import 'package:paper_chat/features/notes/widgets/note_card.dart';
import 'package:paper_chat/features/projects/projects_view_model.dart';
import 'package:paper_chat/features/projects/widgets/add_papers_dialog.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/note.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/models/project.dart';
import 'package:paper_chat/services/notes_repository.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  final SettingsViewModel settingsVM;
  final ProjectsViewModel projectsVM;
  final LibraryViewModel libraryVM;
  final NotesRepository notesRepo;
  final Project project;
  final Function(Paper paper) onOpenPaper;

  const ProjectWorkspaceScreen({
    super.key,
    required this.settingsVM,
    required this.projectsVM,
    required this.libraryVM,
    required this.notesRepo,
    required this.project,
    required this.onOpenPaper,
  });

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedTab = 0; // 0 = Chat, 1 = Ghi chú
  bool _isEditingNote = false;
  Note? _editingNoteTarget;
  String? _draftTitle;
  String? _draftContent;

  void _showAddPapersDialog() {
    final activeProj = widget.projectsVM.activeProject ?? widget.project;
    showDialog(
      context: context,
      builder: (dialogContext) => AddPapersDialog(
        strings: widget.settingsVM.strings,
        project: activeProj,
        availablePapers: widget.libraryVM.papers,
        onSave: (selectedPaperIds) async {
          final currentIds = activeProj.paperIds.toSet();
          for (final id in selectedPaperIds) {
            if (!currentIds.contains(id)) {
              await widget.projectsVM.addPaperToActiveProject(id);
            }
          }
          for (final id in currentIds) {
            if (!selectedPaperIds.contains(id)) {
              await widget.projectsVM.removePaperFromActiveProject(id);
            }
          }
        },
      ),
    );
  }

  void _openCreateNoteDialog(List<Paper> attachedPapers) {
    setState(() {
      _isEditingNote = true;
      _editingNoteTarget = null;
      _draftTitle = 'Ghi chú cho dự án';
      _draftContent = '';
    });
  }

  void _openEditNoteDialog(Note note) {
    setState(() {
      _isEditingNote = true;
      _editingNoteTarget = note;
      _draftTitle = note.sectionTitle;
      _draftContent = note.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.settingsVM.strings;

    return ListenableBuilder(
      listenable: Listenable.merge([widget.projectsVM, widget.settingsVM]),
      builder: (context, _) {
        final project = widget.projectsVM.activeProject ?? widget.project;
        final attachedPapers = widget.projectsVM.getPapersForProject(project);
        final messages = widget.projectsVM.currentProjectMessages;

        final projectPaperIds = attachedPapers.map((p) => p.id).toSet();
        final projectNotes = widget.notesRepo.getAllNotes().where((n) {
          return projectPaperIds.contains(n.paperId) ||
              n.paperId == 'project_${project.id}' ||
              n.paperTitle == project.title;
        }).toList();

        return Stack(
          children: [
            Scaffold(
              backgroundColor: colors.appBackground,
              body: Column(
                children: [
                  // Project Top Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(bottom: BorderSide(color: colors.divider)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.folder_special_rounded, color: colors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    project.title,
                                    style: AppTypography.heading3.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${attachedPapers.length} tài liệu',
                                      style: AppTypography.caption.copyWith(
                                        color: colors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (project.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  project.description,
                                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showAddPapersDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(strings.addFilesToProject),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          tooltip: strings.delete,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: Text(strings.deleteProjectQuestion),
                                content: Text(strings.confirmDeleteProject),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx, false),
                                    child: Text(strings.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx, true),
                                    child: Text(strings.delete, style: const TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              widget.projectsVM.deleteProject(project.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Main Workspace split into Left (Attached Papers List) and Right (Chat / Notes Tabs)
                  Expanded(
                    child: Row(
                      children: [
                        // Left Panel: Attached Papers List
                        Container(
                          width: 280,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border(right: BorderSide(color: colors.divider)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Text(
                                  strings.attachedPapers,
                                  style: AppTypography.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: colors.divider),
                              Expanded(
                                child: attachedPapers.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'Chưa có tài liệu nào trong dự án.\nBấm "Thêm tài liệu" ở trên!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.all(10),
                                        itemCount: attachedPapers.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final paper = attachedPapers[index];
                                          return Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: colors.appBackground,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: colors.divider),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  paper.title,
                                                  style: AppTypography.body.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: colors.textPrimary,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  paper.authors.join(', '),
                                                  style: AppTypography.caption.copyWith(
                                                    color: colors.textSecondary,
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    InkWell(
                                                      onTap: () => widget.onOpenPaper(paper),
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.picture_as_pdf, size: 12, color: colors.primary),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              strings.openPaperInReader,
                                                              style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                                                      tooltip: strings.removeFromProject,
                                                      onPressed: () => widget.projectsVM.removePaperFromActiveProject(paper.id),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),

                        // Right Main Panel with Workspace Tabs [Đoạn chat | Ghi chú]
                        Expanded(
                          child: Column(
                            children: [
                              // Tab Bar Switcher Header
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  border: Border(bottom: BorderSide(color: colors.divider)),
                                ),
                                child: Row(
                                  children: [
                                    _WorkspaceTabButton(
                                      label: 'Đoạn chat',
                                      icon: Icons.forum_outlined,
                                      isSelected: _selectedTab == 0,
                                      onTap: () => setState(() => _selectedTab = 0),
                                    ),
                                    const SizedBox(width: 8),
                                    _WorkspaceTabButton(
                                      label: strings.notes,
                                      icon: Icons.description_outlined,
                                      isSelected: _selectedTab == 1,
                                      onTap: () => setState(() => _selectedTab = 1),
                                    ),
                                  ],
                                ),
                              ),

                              // Tab Body Content
                              Expanded(
                                child: _selectedTab == 0
                                    ? // TAB 0: AI CHAT VIEW
                                      Column(
                                        children: [
                                          // Project Scope Banner
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            color: colors.selectionBackground.withValues(alpha: 0.5),
                                            child: Row(
                                              children: [
                                                Icon(Icons.auto_awesome_rounded, size: 16, color: colors.primary),
                                                const SizedBox(width: 8),
                                                Text(
                                                  strings.projectChatScope,
                                                  style: AppTypography.caption.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colors.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '- Trả lời dựa trên toàn bộ ${attachedPapers.length} bài báo trong dự án',
                                                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Messages List
                                          Expanded(
                                            child: messages.isEmpty
                                                ? Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.forum_outlined, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
                                                        const SizedBox(height: 12),
                                                        Text(
                                                          'Hỏi AI bất kỳ điều gì về các tài liệu trong dự án này!',
                                                          style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Ví dụ: "So sánh phương pháp giữa các bài báo trong dự án này"',
                                                          style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7), fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : ListView.builder(
                                                    controller: _scrollController,
                                                    padding: const EdgeInsets.all(16),
                                                    itemCount: messages.length,
                                                    itemBuilder: (context, index) {
                                                      final msg = messages[index];
                                                      return MessageBubble(
                                                        message: msg,
                                                        strings: strings,
                                                        onCitationTap: (page, excerpt) {
                                                          if (attachedPapers.isNotEmpty) {
                                                            widget.onOpenPaper(attachedPapers.first);
                                                          }
                                                        },
                                                        onSaveNote: () {
                                                          _openCreateNoteDialog(attachedPapers);
                                                        },
                                                        onRetry: () {},
                                                      );
                                                    },
                                                  ),
                                          ),

                                          // Chat Composer
                                          ChatComposer(
                                            strings: strings,
                                            onClearSelectedText: () {},
                                            isStreaming: widget.projectsVM.isStreaming,
                                            onSend: (text) => widget.projectsVM.sendMessage(text),
                                            onStop: () => widget.projectsVM.stopStreaming(),
                                          ),
                                        ],
                                      )
                                    : // TAB 1: NOTES VIEW
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Notes Header with Add Note Button
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Ghi chú dự án (${projectNotes.length})',
                                                  style: AppTypography.subtitle.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colors.textPrimary,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () => _openCreateNoteDialog(attachedPapers),
                                                  icon: const Icon(Icons.add, size: 16),
                                                  label: Text(strings.addNoteTitle),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: colors.primary,
                                                    foregroundColor: colors.onPrimary,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Divider(height: 1, color: colors.divider),

                                          // Notes List
                                          Expanded(
                                            child: projectNotes.isEmpty
                                                ? Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.description_outlined, size: 44, color: colors.textSecondary.withValues(alpha: 0.4)),
                                                        const SizedBox(height: 12),
                                                        Text(
                                                          'Chưa có ghi chú nào trong dự án này',
                                                          style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Bấm "+ Thêm ghi chú mới" để lưu trữ ý tưởng của bạn.',
                                                          style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7), fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : ListView.builder(
                                                    padding: const EdgeInsets.all(16),
                                                    itemCount: projectNotes.length,
                                                    itemBuilder: (context, index) {
                                                      final note = projectNotes[index];
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 12.0),
                                                        child: NoteCard(
                                                          strings: strings,
                                                          note: note,
                                                          onNavigate: () {
                                                            final paper = attachedPapers.firstWhere(
                                                              (p) => p.id == note.paperId,
                                                              orElse: () => attachedPapers.isNotEmpty ? attachedPapers.first : widget.libraryVM.papers.first,
                                                            );
                                                            widget.onOpenPaper(paper);
                                                          },
                                                          onDelete: () async {
                                                            await widget.notesRepo.deleteNote(note.id);
                                                            setState(() {});
                                                          },
                                                          onUpdate: (newContent) async {
                                                            _openEditNoteDialog(note);
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isEditingNote)
              MinimizableNoteEditor(
                strings: strings,
                isEditing: _editingNoteTarget != null,
                initialTitle: _draftTitle,
                initialContent: _draftContent,
                onDelete: _editingNoteTarget != null
                    ? () async {
                        await widget.notesRepo.deleteNote(_editingNoteTarget!.id);
                        setState(() {
                          _isEditingNote = false;
                        });
                      }
                    : null,
                onClose: () {
                  setState(() {
                    _isEditingNote = false;
                  });
                },
                onSave: (title, content) async {
                  final activeProj = widget.projectsVM.activeProject ?? widget.project;
                  if (_editingNoteTarget != null) {
                    final updatedNote = Note(
                      id: _editingNoteTarget!.id,
                      paperId: _editingNoteTarget!.paperId,
                      paperTitle: _editingNoteTarget!.paperTitle,
                      page: _editingNoteTarget!.page,
                      sectionTitle: title,
                      content: content,
                      createdAt: _editingNoteTarget!.createdAt,
                    );
                    await widget.notesRepo.updateNote(updatedNote);
                  } else {
                    final firstPaper = attachedPapers.isNotEmpty ? attachedPapers.first : null;
                    final newNote = Note(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      paperId: firstPaper?.id ?? 'project_${activeProj.id}',
                      paperTitle: firstPaper?.title ?? activeProj.title,
                      page: 0,
                      sectionTitle: title.isNotEmpty ? title : 'Ghi chú dự án',
                      content: content,
                      createdAt: DateTime.now(),
                    );
                    await widget.notesRepo.addNote(newNote);
                  }
                  setState(() {
                    _isEditingNote = false;
                  });
                },
              ),
          ],
        );
      },
    );
  }
}

class _WorkspaceTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkspaceTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? colors.primary : colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
