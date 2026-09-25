import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/features/library/library_view_model.dart';
import 'package:paper_chat/features/library/widgets/empty_state.dart';
import 'package:paper_chat/features/library/widgets/filter_bar.dart';
import 'package:paper_chat/features/library/widgets/import_paper_dialog.dart';
import 'package:paper_chat/features/library/widgets/paper_card.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/paper.dart';

class LibraryScreen extends StatefulWidget {
  final SettingsViewModel settingsVM;
  final LibraryViewModel viewModel;
  final ValueChanged<Paper> onPaperSelected;
  final ValueChanged<Paper>? onAddPaperToProject;
  final ValueChanged<Paper>? onPaperDeleted;

  const LibraryScreen({
    super.key,
    required this.settingsVM,
    required this.viewModel,
    required this.onPaperSelected,
    this.onAddPaperToProject,
    this.onPaperDeleted,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.viewModel.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportPaperDialog(
        strings: widget.settingsVM.strings,
        onSave: (newPaper, bytes, fileName) async {
          await widget.viewModel.uploadPaper(
            bytes,
            fileName,
            title: newPaper.title.isNotEmpty ? newPaper.title : null,
            authors: newPaper.authors.isNotEmpty ? newPaper.authors.join(', ') : null,
            year: newPaper.year > 0 ? newPaper.year : null,
            collection: newPaper.collection.isNotEmpty ? newPaper.collection : null,
            tags: newPaper.tags.isNotEmpty ? newPaper.tags.join(', ') : null,
            abstractText: newPaper.abstractText.isNotEmpty ? newPaper.abstractText : null,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.settingsVM.strings.addPaperSuccess),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeletePaper(Paper paper) async {
    final colors = AppColorsExtension.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text(
              'Xóa bài báo',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa bài báo sau khỏi thư viện?',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.appBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
              ),
              child: Text(
                paper.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lưu ý: Hệ thống sẽ cascade xóa vĩnh viễn toàn bộ dữ liệu phân tích, các đoạn chunking, vector embedding và file PDF lưu trên máy chủ.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Hủy', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.viewModel.deletePaper(paper.id);
      if (success) {
        widget.onPaperDeleted?.call(paper);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã xóa bài báo thành công.'
                  : 'Xóa bài báo thất bại. Vui lòng thử lại.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            _showImportDialog,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.viewModel, widget.settingsVM]),
          builder: (context, _) {
            final strings = widget.settingsVM.strings;
            final papers = widget.viewModel.filteredPapers;

            return Scaffold(
              backgroundColor: colors.appBackground,
              appBar: AppBar(
                title: Text(strings.library),
                backgroundColor: colors.surface,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: '${strings.importPaper} (Ctrl+O)',
                    onPressed: _showImportDialog,
                    color: colors.textPrimary,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Container(
                    color: colors.surfaceElevated,
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        hintText: strings.searchTitleAuthors,
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.textSecondary,
                        ),
                        filled: true,
                        fillColor: colors.appBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: ListenableBuilder(
                          listenable: _searchController,
                          builder: (context, _) {
                            if (_searchController.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                widget.viewModel.searchQuery = '';
                              },
                              color: colors.textSecondary,
                            );
                          },
                        ),
                      ),
                      onChanged: (val) => widget.viewModel.searchQuery = val,
                    ),
                  ),
                  FilterBar(
                    settingsVM: widget.settingsVM,
                    viewModel: widget.viewModel,
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final hasFilters =
                            widget.viewModel.searchQuery.isNotEmpty ||
                            widget.viewModel.showFavoritesOnly ||
                            widget.viewModel.selectedCollection != null ||
                            widget.viewModel.selectedTag != null;

                        if (papers.isEmpty) {
                          return EmptyState(
                            settingsVM: widget.settingsVM,
                            isFiltered: hasFilters,
                            onClearFilters: widget.viewModel.clearFilters,
                            onImport: _showImportDialog,
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            if (isWide) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 3.2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                itemCount: papers.length,
                                itemBuilder: (context, index) {
                                  final paper = papers[index];
                                  return PaperCard(
                                    paper: paper,
                                    onTap: () => widget.onPaperSelected(paper),
                                    onToggleFavorite: () => widget.viewModel
                                        .toggleFavorite(paper.id),
                                    onAddToProject:
                                        widget.onAddPaperToProject != null
                                        ? () => widget.onAddPaperToProject
                                              ?.call(paper)
                                        : null,
                                    onDelete: () => _confirmDeletePaper(paper),
                                    onMetadataUpdated: () => setState(() {}),
                                  );
                                },
                              );
                            } else {
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: papers.length,
                                itemBuilder: (context, index) {
                                  final paper = papers[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: PaperCard(
                                      paper: paper,
                                      onTap: () =>
                                          widget.onPaperSelected(paper),
                                      onToggleFavorite: () => widget.viewModel
                                          .toggleFavorite(paper.id),
                                      onAddToProject:
                                          widget.onAddPaperToProject != null
                                          ? () => widget.onAddPaperToProject
                                                ?.call(paper)
                                          : null,
                                      onDelete: () => _confirmDeletePaper(paper),
                                      onMetadataUpdated: () => setState(() {}),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
