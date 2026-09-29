import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/chat/chat_view_model.dart';
import 'package:paper_chat/features/chat/widgets/chat_composer.dart';
import 'package:paper_chat/features/chat/widgets/message_bubble.dart';
import 'package:paper_chat/features/chat/widgets/starter_prompts.dart';
import 'package:paper_chat/features/notes/widgets/note_editor_dialog.dart';
import 'package:paper_chat/features/reader/reader_view_model.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/note.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/notes_repository.dart';

class ChatPanel extends StatefulWidget {
  final SettingsViewModel settingsVM;
  final ChatViewModel chatViewModel;
  final ReaderViewModel readerViewModel;
  final NotesRepository notesRepository;
  final Paper paper;
  final void Function({
    Note? note,
    String? initialTitle,
    String? initialContent,
  })?
  onOpenNoteEditor;
  final VoidCallback? onClose;

  const ChatPanel({
    super.key,
    required this.settingsVM,
    required this.chatViewModel,
    required this.readerViewModel,
    required this.notesRepository,
    required this.paper,
    this.onOpenNoteEditor,
    this.onClose,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _userScrolledUp = false;
  int _selectedTab = 0; // 0=Chat, 1=History, 2=Notes

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final isAtBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50;
      setState(() {
        _userScrolledUp = !isAtBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSaveNote(String content) {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      paperId: widget.paper.id,
      paperTitle: widget.paper.title,
      page: widget.readerViewModel.currentPage,
      sectionTitle:
          widget.readerViewModel.currentPageContent?.sectionTitle ?? 'General',
      content: content,
      createdAt: DateTime.now(),
    );
    widget.notesRepository.addNote(note);
    setState(() {}); // refresh notes tab
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.settingsVM.strings.savedToNotes),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openNoteEditor([Note? existingNote]) {
    if (widget.onOpenNoteEditor != null) {
      widget.onOpenNoteEditor!(
        note: existingNote,
        initialTitle: existingNote?.sectionTitle,
        initialContent: existingNote?.content,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => NoteEditorDialog(
        strings: widget.settingsVM.strings,
        initialTitle:
            existingNote?.sectionTitle ??
            widget.settingsVM.strings.newNoteTitle,
        initialContent: existingNote?.content ?? '',
        isEditing: existingNote != null,
        onDelete: existingNote != null
            ? () {
                widget.notesRepository.deleteNote(existingNote.id);
                setState(() {});
              }
            : null,
        onSave: (title, content) {
          if (content.isNotEmpty) {
            if (existingNote != null) {
              final updated = Note(
                id: existingNote.id,
                paperId: existingNote.paperId,
                paperTitle: existingNote.paperTitle,
                page: existingNote.page,
                sectionTitle: title,
                content: content,
                createdAt: existingNote.createdAt,
              );
              widget.notesRepository.updateNote(updated);
            } else {
              final note = Note(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                paperId: widget.paper.id,
                paperTitle: widget.paper.title,
                page: widget.readerViewModel.currentPage,
                sectionTitle: title,
                content: content,
                createdAt: DateTime.now(),
              );
              widget.notesRepository.addNote(note);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.settingsVM.strings.savedToNotes),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([widget.chatViewModel, widget.settingsVM]),
      builder: (context, _) {
        final messages = widget.chatViewModel.currentMessages;
        final strings = widget.settingsVM.strings;

        if (widget.chatViewModel.isStreaming && !_userScrolledUp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        return Container(
          color: colors.surface,
          child: Column(
            children: [
              // Top Tab Header: Chat | Lịch sử | Ghi chú + Collapse Button
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _TabHeaderButton(
                              label: strings.chatTab,
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                            const SizedBox(width: 16),
                            _TabHeaderButton(
                              label: strings.historyTab,
                              isSelected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                            const SizedBox(width: 16),
                            _TabHeaderButton(
                              label: strings.notesTab,
                              isSelected: _selectedTab == 2,
                              onTap: () => setState(() => _selectedTab = 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.onClose != null) ...[
                      Tooltip(
                        message: strings.collapseChat,
                        child: IconButton(
                          icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
                          onPressed: widget.onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Scope Sub-Header bar
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.paper.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.selectionBackground,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.chatViewModel.scope == 'selection'
                                ? strings.selectionScope
                                : strings.entirePaperScope,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 12,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Panel Content based on selected tab
              Expanded(
                child: _selectedTab == 0
                    ? _buildChatContent(messages, colors)
                    : _selectedTab == 1
                    ? _buildHistoryContent(colors)
                    : _buildNotesContent(colors),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatContent(List<dynamic> messages, AppColorsExtension colors) {
    final strings = widget.settingsVM.strings;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (messages.isEmpty)
                StarterPrompts(
                  strings: strings,
                  onPromptSelected: widget.chatViewModel.sendMessage,
                )
              else
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return MessageBubble(
                      strings: strings,
                      message: msg,
                      onCitationTap: widget.readerViewModel.navigateToCitation,
                      onSaveNote: () => _handleSaveNote(msg.content),
                      onRetry: widget.chatViewModel.retryLast,
                    );
                  },
                ),
              if (_userScrolledUp && messages.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.extended(
                      onPressed: _scrollToBottom,
                      label: Text(
                        strings.newMessages,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.arrow_downward, size: 14),
                      backgroundColor: colors.surfaceElevated,
                      foregroundColor: colors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Composer at bottom
        ChatComposer(
          strings: strings,
          selectedText: widget.chatViewModel.selectedTextForChat,
          onClearSelectedText: widget.chatViewModel.clearSelectedText,
          onSend: widget.chatViewModel.sendMessage,
          isStreaming: widget.chatViewModel.isStreaming,
          onStop: widget.chatViewModel.stopStreaming,
        ),
      ],
    );
  }

  Widget _buildHistoryContent(AppColorsExtension colors) {
    final strings = widget.settingsVM.strings;
    final history = widget.chatViewModel.chatHistory;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(
                '${strings.historyTab} (${history.length})',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.chatViewModel.isHistoryLoading
                    ? null
                    : widget.chatViewModel.loadChatHistory,
                tooltip: strings.historyTab,
                icon: const Icon(Icons.refresh, size: 16),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
        Expanded(
          child: widget.chatViewModel.isHistoryLoading && history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        strings.loadingChatHistory,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : history.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.chatViewModel.historyError == null
                              ? Icons.history_rounded
                              : Icons.error_outline,
                          size: 30,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.chatViewModel.historyError == null
                              ? strings.noChatHistory
                              : strings.chatHistoryLoadFailed,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        if (widget.chatViewModel.historyError != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: widget.chatViewModel.loadChatHistory,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: Text(strings.retry),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final question = entry['question']?.toString() ?? '';
                    final answer = entry['answer']?.toString() ?? '';
                    final createdAt = DateTime.tryParse(
                      entry['createdAt']?.toString() ?? '',
                    )?.toLocal();
                    final timestamp = createdAt == null
                        ? null
                        : '${MaterialLocalizations.of(context).formatMediumDate(createdAt)} · '
                              '${TimeOfDay.fromDateTime(createdAt).format(context)}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.divider),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          12,
                        ),
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          size: 17,
                          color: colors.primary,
                        ),
                        title: Text(
                          question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: timestamp == null
                            ? null
                            : Text(
                                timestamp,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                ),
                              ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SelectableText(
                              answer,
                              style: AppTypography.body.copyWith(
                                fontSize: 12,
                                height: 1.45,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotesContent(AppColorsExtension colors) {
    final strings = widget.settingsVM.strings;
    final paperNotes = widget.notesRepository.getNotesForPaper(widget.paper.id);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Text(
                '${strings.paperNotesHeader} (${paperNotes.length})',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openNoteEditor(),
                icon: const Icon(Icons.add, size: 14),
                label: Text(
                  strings.createNote,
                  style: AppTypography.caption.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
        Expanded(
          child: paperNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 36,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.noNotesYet,
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          strings.noNotesHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: paperNotes.length,
                  itemBuilder: (context, index) {
                    final note = paperNotes[index];
                    return InkWell(
                      onTap: () {
                        widget.readerViewModel.goToPage(note.page);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.selectionBackground,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    strings.pageTag(note.page + 1),
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note.sectionTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: colors.textSecondary,
                                  ),
                                  onPressed: () => _openNoteEditor(note),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  tooltip: strings.editNote,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                    color: colors.textSecondary,
                                  ),
                                  onPressed: () {
                                    widget.notesRepository.deleteNote(note.id);
                                    setState(() {});
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  tooltip: strings.deleteNote,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              note.content,
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                                height: 1.4,
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
    );
  }
}

class _TabHeaderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabHeaderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.subtitle.copyWith(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
