import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';

class NoteEditorDialog extends StatefulWidget {
  final AppStrings strings;
  final String? initialTitle;
  final String? initialContent;
  final bool isEditing;
  final VoidCallback? onDelete;
  final Function(String title, String content) onSave;

  const NoteEditorDialog({
    super.key,
    required this.strings,
    this.initialTitle,
    this.initialContent,
    this.isEditing = false,
    this.onDelete,
    required this.onSave,
  });

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _selectedStyle = 'Bình thường';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? widget.strings.newNoteTitle,
    );
    _contentController = TextEditingController(
      text: widget.initialContent ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = selection.textInside(text);
      final newText = selection.textBefore(text) +
          prefix +
          selectedText +
          suffix +
          selection.textAfter(text);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    } else {
      final cursor = selection.isValid ? selection.start : text.length;
      final newText = text.substring(0, cursor) + prefix + suffix + text.substring(cursor);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + prefix.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.strings;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title TextField & Delete Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: strings.noteTitleHint,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (widget.isEditing && widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
                    tooltip: strings.deleteNote,
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete?.call();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 10),

            // Formatting Toolbar Row (Undo, Redo, Style Dropdown, Bold, Italic, Link, Code, Lists, Quote)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.undo, size: 16, color: colors.textSecondary),
                      onPressed: () {},
                      tooltip: 'Undo',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: Icon(Icons.redo, size: 16, color: colors.textSecondary),
                      onPressed: () {},
                      tooltip: 'Redo',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    Container(height: 16, width: 1, color: colors.divider, margin: const EdgeInsets.symmetric(horizontal: 4)),

                    // Style dropdown (Bình thường / Heading)
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStyle,
                        style: AppTypography.caption.copyWith(color: colors.textPrimary),
                        dropdownColor: colors.surface,
                        items: [
                          DropdownMenuItem(value: 'Bình thường', child: Text(strings.normalText)),
                          DropdownMenuItem(value: 'Tiêu đề (Heading)', child: Text(strings.headingText)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStyle = val);
                            if (val.contains('Heading')) {
                              _insertFormatting('# ');
                            }
                          }
                        },
                      ),
                    ),
                    Container(height: 16, width: 1, color: colors.divider, margin: const EdgeInsets.symmetric(horizontal: 4)),

                    // Bold (B)
                    IconButton(
                      icon: Text('B', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 14)),
                      onPressed: () => _insertFormatting('**', '**'),
                      tooltip: 'Bold (Ctrl+B)',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    // Italic (I)
                    IconButton(
                      icon: Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 14)),
                      onPressed: () => _insertFormatting('*', '*'),
                      tooltip: 'Italic (Ctrl+I)',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    // Link
                    IconButton(
                      icon: Icon(Icons.link, size: 16, color: colors.textSecondary),
                      onPressed: () => _insertFormatting('[', '](url)'),
                      tooltip: 'Link',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    // Code Block
                    IconButton(
                      icon: Icon(Icons.code, size: 16, color: colors.textSecondary),
                      onPressed: () => _insertFormatting('`', '`'),
                      tooltip: 'Code',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    Container(height: 16, width: 1, color: colors.divider, margin: const EdgeInsets.symmetric(horizontal: 4)),

                    // Bullet list
                    IconButton(
                      icon: Icon(Icons.format_list_bulleted, size: 16, color: colors.textSecondary),
                      onPressed: () => _insertFormatting('- '),
                      tooltip: 'Bullet list',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    // Numbered list
                    IconButton(
                      icon: Icon(Icons.format_list_numbered, size: 16, color: colors.textSecondary),
                      onPressed: () => _insertFormatting('1. '),
                      tooltip: 'Numbered list',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    // Quote
                    IconButton(
                      icon: Icon(Icons.format_quote, size: 16, color: colors.textSecondary),
                      onPressed: () => _insertFormatting('> '),
                      tooltip: 'Quote',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    // Horizontal Rule
                    IconButton(
                      icon: Icon(Icons.horizontal_rule, size: 16, color: colors.textSecondary),
                      onPressed: () => _insertFormatting('\n---\n'),
                      tooltip: 'Divider',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Note Content Text Area
            SizedBox(
              height: 220,
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: strings.noteContentHint,
                  hintStyle: AppTypography.body.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: colors.surfaceElevated.withValues(alpha: 0.3),
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
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer Action Buttons: Cancel & Save
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(strings.cancel),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();
                    widget.onSave(
                      title.isEmpty ? strings.newNoteTitle : title,
                      content,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(strings.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

