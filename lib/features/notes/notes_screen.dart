import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/features/notes/notes_view_model.dart';
import 'package:paper_chat/features/notes/widgets/note_card.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/note.dart';
import 'package:paper_chat/shared/widgets/demo_badge.dart';

class NotesScreen extends StatelessWidget {
  final SettingsViewModel settingsVM;
  final NotesViewModel viewModel;
  final Function(String paperId, int page) onNavigateToPaper;

  const NotesScreen({
    super.key,
    required this.settingsVM,
    required this.viewModel,
    required this.onNavigateToPaper,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: settingsVM,
      builder: (context, _) {
        final strings = settingsVM.strings;

        return Scaffold(
          backgroundColor: colors.appBackground,
          appBar: AppBar(
            title: Text(strings.notes),
            backgroundColor: colors.surface,
            actions: [
              const DemoBadge(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: strings.exportMarkdown,
                onPressed: () async {
                  final path = await viewModel.exportAsMarkdown();
                  if (context.mounted) {
                    if (path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.exportedTo(path))),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.exportFailed)),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: strings.searchNotes,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colors.surface,
                  ),
                  onChanged: (value) {
                    viewModel.searchQuery = value;
                  },
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    final notes = viewModel.filteredNotes;
                    if (notes.isEmpty) {
                      return Center(
                        child: Text(
                          strings.noNotesYet,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: NoteCard(
                            strings: strings,
                            note: note,
                            onNavigate: () => onNavigateToPaper(note.paperId, note.page),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(strings.deleteNoteQuestion),
                                  content: Text(strings.confirmDeleteNote),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(strings.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(strings.delete, style: const TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                viewModel.deleteNote(note.id);
                              }
                            },
                            onUpdate: (updatedContent) {
                              final newNote = Note(
                                id: note.id,
                                paperId: note.paperId,
                                paperTitle: note.paperTitle,
                                page: note.page,
                                sectionTitle: note.sectionTitle,
                                content: updatedContent,
                                createdAt: note.createdAt,
                              );
                              viewModel.updateNote(newNote);
                            },
                          ),
                        );
                      },
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
