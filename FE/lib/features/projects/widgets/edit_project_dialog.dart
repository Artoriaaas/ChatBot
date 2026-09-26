import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/models/project.dart';

class EditProjectDialog extends StatefulWidget {
  final AppStrings strings;
  final Project project;
  final List<Paper> availablePapers;
  final Function(String newTitle, List<String> paperIds) onSave;
  final VoidCallback onDelete;
  final Function(Project project)? onAddMoreFiles;

  const EditProjectDialog({
    super.key,
    required this.strings,
    required this.project,
    required this.availablePapers,
    required this.onSave,
    required this.onDelete,
    this.onAddMoreFiles,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late TextEditingController _titleController;
  late List<String> _currentPaperIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _currentPaperIds = List<String>.from(widget.project.paperIds);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Paper? _findPaper(String id) {
    try {
      return widget.availablePapers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _removePaper(String id) {
    setState(() {
      _currentPaperIds.remove(id);
    });
  }

  void _showAddFileDialog() {
    // Show picker for remaining papers
    final unselectedPapers = widget.availablePapers
        .where((p) => !_currentPaperIds.contains(p.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = AppColorsExtension.of(ctx);
        String searchQuery = '';
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final filtered = unselectedPapers.where((paper) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return paper.title.toLowerCase().contains(q) ||
                  paper.authors.any((a) => a.toLowerCase().contains(q));
            }).toList();

            return AlertDialog(
              backgroundColor: colors.surface,
              title: Text(widget.strings.addFilesToProject, style: TextStyle(color: colors.textPrimary, fontSize: 16)),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (val) => setDialogState(() => searchQuery = val),
                      style: AppTypography.caption.copyWith(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: widget.strings.searchDocuments,
                        hintStyle: AppTypography.caption.copyWith(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                        ),
                        prefixIcon: Icon(Icons.search, size: 14, color: colors.textSecondary),
                        filled: true,
                        fillColor: colors.appBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                unselectedPapers.isEmpty
                                    ? 'Tất cả tài liệu hiện có đã được thêm.'
                                    : 'Không tìm thấy tài liệu phù hợp.',
                                style: TextStyle(color: colors.textSecondary, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final paper = filtered[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.article_outlined, color: colors.primary, size: 18),
                                  title: Text(paper.title, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                                  subtitle: Text(paper.authorsShort, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                                  trailing: Icon(Icons.add_circle_outline, size: 18, color: colors.primary),
                                  onTap: () {
                                    setState(() {
                                      _currentPaperIds.add(paper.id);
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(widget.strings.cancel, style: TextStyle(color: colors.textSecondary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.strings;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colors.surface,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title & Close 'x' button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit project',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Project Title Input Box with leading folder icon
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primary, width: 1.5),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.folder_outlined, color: colors.textSecondary, size: 18),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: colors.divider,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Label: Source files
            Text(
              'Source files',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),

            // Source Files Card List
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                children: [
                  // List of Attached Files
                  if (_currentPaperIds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '(Chưa có tài liệu nào trong dự án)',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ..._currentPaperIds.map((id) {
                      final paper = _findPaper(id);
                      final title = paper?.title ?? 'Tài liệu #$id';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: colors.divider.withValues(alpha: 0.6))),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file_outlined, size: 16, color: colors.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.caption.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _removePaper(id),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(Icons.close, size: 15, color: colors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Bottom Item: Add file
                  InkWell(
                    onTap: _showAddFileDialog,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(
                        children: [
                          Icon(Icons.note_add_outlined, size: 16, color: colors.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            'Add file',
                            style: AppTypography.caption.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Footer: Left = Remove local project, Right = Cancel & Save
            Row(
              children: [
                // Light red pill button for Remove local project
                InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(strings.deleteProjectQuestion),
                        content: Text(strings.confirmDeleteProject),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(strings.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text(strings.delete, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      widget.onDelete();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Remove local project',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),

                // Save Button (Dark solid button matching Image 2)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E1E1E),
                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isNotEmpty) {
                      widget.onSave(title, _currentPaperIds);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
