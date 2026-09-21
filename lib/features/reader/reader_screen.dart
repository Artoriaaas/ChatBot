import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_chat/features/chat/chat_panel.dart';
import 'package:paper_chat/features/chat/chat_view_model.dart';
import 'package:paper_chat/features/notes/widgets/note_editor_dialog.dart';
import 'package:paper_chat/features/reader/reader_view_model.dart';
import 'package:paper_chat/features/reader/widgets/reader_pane.dart';
import 'package:paper_chat/features/reader/widgets/reader_toolbar.dart';
import 'package:paper_chat/features/reader/widgets/table_of_contents.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/note.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/notes_repository.dart';
import 'package:paper_chat/shared/widgets/resizable_splitter.dart';

class ReaderScreen extends StatefulWidget {
  final Paper paper;
  final SettingsViewModel settingsViewModel;
  final ReaderViewModel readerViewModel;
  final ChatViewModel chatViewModel;
  final NotesRepository notesRepository;
  final VoidCallback onBack;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;

  const ReaderScreen({
    super.key,
    required this.paper,
    required this.settingsViewModel,
    required this.readerViewModel,
    required this.chatViewModel,
    required this.notesRepository,
    required this.onBack,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double _tocWidth = 220;
  double _chatWidth = 400;
  bool _isTocOpen = false;
  bool _isHighlightMode = false;
  int _activeNarrowTab = 0; // 0=reader, 1=chat (for narrow mode)

  @override
  void initState() {
    super.initState();
    widget.readerViewModel.openPaper(widget.paper);
    widget.chatViewModel.setCurrentPaper(widget.paper);
  }

  void _handleAskAi() {
    if (widget.readerViewModel.selectedText != null) {
      widget.chatViewModel.setSelectedText(widget.readerViewModel.selectedText);
    }
  }

  void _handleExplain() {
    if (widget.readerViewModel.selectedText != null) {
      final text = widget.readerViewModel.selectedText!;
      widget.chatViewModel.setSelectedText(text);
      final isVi = widget.settingsViewModel.strings.isVi;
      widget.chatViewModel.sendMessage(isVi ? 'Giải thích đoạn văn này: "$text"' : 'Explain this text: "$text"');
    }
  }

  void _handleSummarize() {
    if (widget.readerViewModel.selectedText != null) {
      final text = widget.readerViewModel.selectedText!;
      widget.chatViewModel.setSelectedText(text);
      final isVi = widget.settingsViewModel.strings.isVi;
      widget.chatViewModel.sendMessage(isVi ? 'Tóm tắt đoạn văn này: "$text"' : 'Summarize this text: "$text"');
    }
  }

  void _handleCreateNoteFromSelection() {
    final text = widget.readerViewModel.selectedText;
    final strings = widget.settingsViewModel.strings;
    showDialog(
      context: context,
      builder: (context) => NoteEditorDialog(
        strings: strings,
        initialTitle: strings.newNoteTitle,
        initialContent: text != null && text.isNotEmpty ? '"> $text"\n\n' : '',
        onSave: (title, content) {
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
              content: Text(strings.savedToNotes),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_isTocOpen) {
            setState(() => _isTocOpen = false);
          }
          widget.readerViewModel.clearSelection();
        },
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            return Column(
              children: [
                // Top Reader Toolbar
                ListenableBuilder(
                  listenable: widget.readerViewModel,
                  builder: (context, _) => ReaderToolbar(
                    settingsVM: widget.settingsViewModel,
                    onToggleToc: () => setState(() => _isTocOpen = !_isTocOpen),
                    isTocOpen: _isTocOpen,
                    currentPage: widget.readerViewModel.currentPage,
                    totalPages: widget.readerViewModel.totalPages,
                    onGoToPage: widget.readerViewModel.goToPage,
                    onPrevPage: () => widget.readerViewModel.goToPage(widget.readerViewModel.currentPage - 1),
                    onNextPage: () => widget.readerViewModel.goToPage(widget.readerViewModel.currentPage + 1),
                    zoomLevel: widget.readerViewModel.zoomLevel,
                    onZoomIn: () => widget.readerViewModel.setZoom(widget.readerViewModel.zoomLevel + 0.1),
                    onZoomOut: () => widget.readerViewModel.setZoom(widget.readerViewModel.zoomLevel - 0.1),
                    onFitWidth: () => widget.readerViewModel.setZoom(1.0),
                    isHighlightMode: _isHighlightMode,
                    onToggleHighlightMode: () => setState(() => _isHighlightMode = !_isHighlightMode),
                    searchQuery: widget.readerViewModel.searchQuery,
                    onSearch: widget.readerViewModel.search,
                    onNextSearchResult: widget.readerViewModel.nextSearchResult,
                    onPrevSearchResult: widget.readerViewModel.prevSearchResult,
                    searchResultCount: widget.readerViewModel.searchResults.length,
                    currentSearchIndex: widget.readerViewModel.currentSearchResultIndex,
                  ),
                ),

                // Main Split Region (TOC Popover -> PDF Reader Pane -> Splitter -> Chat Panel)
                Expanded(
                  child: Row(
                    children: [
                      // Table of Contents Drawer/Panel (collapsible popover style)
                      if (_isTocOpen && !isNarrow) ...[
                        SizedBox(
                          width: _tocWidth,
                          child: ListenableBuilder(
                            listenable: widget.readerViewModel,
                            builder: (context, _) => TableOfContents(
                              settingsVM: widget.settingsViewModel,
                              paper: widget.paper,
                              currentPage: widget.readerViewModel.currentPage,
                              onPageSelected: (page) {
                                widget.readerViewModel.goToPage(page);
                              },
                              onClose: () => setState(() => _isTocOpen = false),
                            ),
                          ),
                        ),
                        VerticalDragHandle(
                          onDragUpdate: (delta) {
                            setState(() {
                              _tocWidth = (_tocWidth + delta).clamp(180.0, 320.0);
                            });
                          },
                        ),
                      ],

                      // Main PDF Reader Pane
                      if (!isNarrow || _activeNarrowTab == 0)
                        Expanded(
                          child: ListenableBuilder(
                            listenable: Listenable.merge([widget.readerViewModel, widget.settingsViewModel]),
                            builder: (context, _) {
                              final pageContent = widget.readerViewModel.currentPageContent;
                              if (pageContent == null) return const Center(child: CircularProgressIndicator());
                              return ReaderPane(
                                strings: widget.settingsViewModel.strings,
                                pageContent: pageContent,
                                zoomLevel: widget.readerViewModel.zoomLevel,
                                searchQuery: widget.readerViewModel.searchQuery,
                                highlights: widget.readerViewModel.currentHighlights,
                                highlightedCitationText: widget.readerViewModel.highlightedCitationText,
                                onTextSelected: (text) {
                                  widget.readerViewModel.selectText(text);
                                  if (_isHighlightMode) {
                                    widget.readerViewModel.addHighlight(text);
                                  }
                                },
                                onClearSelection: widget.readerViewModel.clearSelection,
                                onExplain: _handleExplain,
                                onSummarize: _handleSummarize,
                                onAskAi: _handleAskAi,
                                onAddNote: _handleCreateNoteFromSelection,
                                onToggleHighlight: (text) {
                                  if (widget.readerViewModel.currentHighlights.contains(text)) {
                                    widget.readerViewModel.removeHighlight(text);
                                  } else {
                                    widget.readerViewModel.addHighlight(text);
                                  }
                                },
                              );
                            },
                          ),
                        ),

                      // Resizable Right Panel (Chat & Notes)
                      if (!isNarrow && _activeNarrowTab != 1) ...[
                        VerticalDragHandle(
                          onDragUpdate: (delta) {
                            setState(() {
                              _chatWidth = (_chatWidth - delta).clamp(300.0, 600.0);
                            });
                          },
                        ),
                        SizedBox(
                          width: _chatWidth,
                          child: ChatPanel(
                            settingsVM: widget.settingsViewModel,
                            chatViewModel: widget.chatViewModel,
                            readerViewModel: widget.readerViewModel,
                            notesRepository: widget.notesRepository,
                            paper: widget.paper,
                          ),
                        ),
                      ],

                      // Narrow mode full screen Chat view
                      if (isNarrow && _activeNarrowTab == 1)
                        Expanded(
                          child: ChatPanel(
                            settingsVM: widget.settingsViewModel,
                            chatViewModel: widget.chatViewModel,
                            readerViewModel: widget.readerViewModel,
                            notesRepository: widget.notesRepository,
                            paper: widget.paper,
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom Navigation Bar for narrow mode (<1000px width)
                if (isNarrow)
                  NavigationBar(
                    selectedIndex: _activeNarrowTab,
                    onDestinationSelected: (index) => setState(() => _activeNarrowTab = index),
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.menu_book), label: 'Reader'),
                      NavigationDestination(icon: Icon(Icons.chat), label: 'Chat & Notes'),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
