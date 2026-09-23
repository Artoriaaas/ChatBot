import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/models/paper.dart';

class CreateProjectDialog extends StatefulWidget {
  final AppStrings strings;
  final List<Paper> availablePapers;
  final Function(String title, String description, List<String> paperIds) onCreate;

  const CreateProjectDialog({
    super.key,
    required this.strings,
    required this.availablePapers,
    required this.onCreate,
  });

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final Set<String> _selectedPaperIds = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colors.surface,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.folder_special_rounded, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.strings.createProject,
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Project Title Input
            Text(
              widget.strings.projectName,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.strings.projectNameHint,
                hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: colors.appBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Project Description Input
            Text(
              widget.strings.projectDesc,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 2,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.strings.projectDescHint,
                hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: colors.appBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Select Initial Papers
            Text(
              widget.strings.selectInitialPapers,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
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
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.appBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.divider),
                ),
                child: Builder(
                  builder: (context) {
                    final filteredPapers = widget.availablePapers.where((p) {
                      if (_searchQuery.trim().isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      return p.title.toLowerCase().contains(q) ||
                          p.authors.any((a) => a.toLowerCase().contains(q));
                    }).toList();

                    if (filteredPapers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Không tìm thấy tài liệu phù hợp',
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredPapers.length,
                      itemBuilder: (context, index) {
                        final paper = filteredPapers[index];
                        final isSelected = _selectedPaperIds.contains(paper.id);
                        return Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                          dense: true,
                          title: Text(
                            paper.title,
                            style: AppTypography.caption.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            paper.authors.join(', '),
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedPaperIds.add(paper.id);
                              } else {
                                _selectedPaperIds.remove(paper.id);
                              }
                            });
                          },
                            activeColor: colors.primary,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions (Cancel / Create)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Hủy',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isNotEmpty) {
                      widget.onCreate(
                        title,
                        _descController.text.trim(),
                        _selectedPaperIds.toList(),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(widget.strings.createProject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

