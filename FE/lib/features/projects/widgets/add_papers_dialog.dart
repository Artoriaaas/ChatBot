import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/models/project.dart';

class AddPapersDialog extends StatefulWidget {
  final AppStrings strings;
  final Project project;
  final List<Paper> availablePapers;
  final Function(Set<String> selectedPaperIds) onSave;

  const AddPapersDialog({
    super.key,
    required this.strings,
    required this.project,
    required this.availablePapers,
    required this.onSave,
  });

  @override
  State<AddPapersDialog> createState() => _AddPapersDialogState();
}

class _AddPapersDialogState extends State<AddPapersDialog> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedPaperIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedPaperIds = Set<String>.from(widget.project.paperIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.strings;

    final filteredPapers = widget.availablePapers.where((paper) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return paper.title.toLowerCase().contains(q) ||
          paper.authors.any((a) => a.toLowerCase().contains(q));
    }).toList();

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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_to_photos_rounded, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${strings.addFilesToProject}: ${widget.project.title}',
                    style: AppTypography.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar Field
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: strings.searchDocuments,
                hintStyle: AppTypography.caption.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(Icons.search, size: 16, color: colors.textSecondary),
                filled: true,
                fillColor: colors.appBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Filtered Papers List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.appBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.divider),
                ),
                child: filteredPapers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Không tìm thấy bài báo phù hợp',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredPapers.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: colors.divider.withValues(alpha: 0.5)),
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
                                fontSize: 11,
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
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons (Hủy / Lưu thay đổi)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.cancel, style: TextStyle(color: colors.textSecondary)),
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
                    widget.onSave(_selectedPaperIds);
                    Navigator.pop(context);
                  },
                  child: Text(strings.saveChanges),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

