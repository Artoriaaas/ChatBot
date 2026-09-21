import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';

class MinimizableNoteEditor extends StatefulWidget {
  final AppStrings strings;
  final String? initialTitle;
  final String? initialContent;
  final bool isEditing;
  final VoidCallback? onDelete;
  final VoidCallback onClose;
  final Function(String title, String content) onSave;

  const MinimizableNoteEditor({
    super.key,
    required this.strings,
    this.initialTitle,
    this.initialContent,
    this.isEditing = false,
    this.onDelete,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<MinimizableNoteEditor> createState() => _MinimizableNoteEditorState();
}

class _MinimizableNoteEditorState extends State<MinimizableNoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isMinimized = false;
  Offset _dragOffset = const Offset(24, 24);
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

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    widget.onSave(
      title.isEmpty ? widget.strings.newNoteTitle : title,
      content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.strings;

    if (_isMinimized) {
      // Draggable Minimized Floating Badge at bottom-right (or user-dragged offset)
      return Positioned(
        bottom: _dragOffset.dy,
        right: _dragOffset.dx,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _dragOffset = Offset(
                (_dragOffset.dx - details.delta.dx).clamp(10.0, MediaQuery.of(context).size.width - 260.0),
                (_dragOffset.dy - details.delta.dy).clamp(10.0, MediaQuery.of(context).size.height - 80.0),
              );
            });
          },
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(24),
            color: colors.surface,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drag_indicator, size: 16, color: colors.textSecondary.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_note_rounded, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      _titleController.text.isEmpty ? strings.newNoteTitle : _titleController.text,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Mở lại (Ctrl+N)',
                    child: InkWell(
                      onTap: _toggleMinimize,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.open_in_full_rounded, size: 13, color: colors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Mở lại',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: strings.save,
                    child: IconButton(
                      icon: Icon(Icons.check_circle_rounded, size: 20, color: colors.primary),
                      onPressed: _handleSave,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Expanded Window (Card Overlay with Minimize Button)
    return Center(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): _toggleMinimize,
        },
        child: Material(
          elevation: 16,
          borderRadius: BorderRadius.circular(16),
          color: colors.surface,
          child: Container(
            width: 580,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Icon / Title TextField / Minimize / Delete / Close
                Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: colors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        style: AppTypography.subtitle.copyWith(
                          fontSize: 18,
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
                    IconButton(
                      icon: Icon(Icons.remove, color: colors.textSecondary, size: 20),
                      tooltip: 'Thu gọn (Ctrl+N)',
                      onPressed: _toggleMinimize,
                    ),
                    if (widget.isEditing && widget.onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
                        tooltip: strings.deleteNote,
                        onPressed: widget.onDelete,
                      ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                      tooltip: strings.cancel,
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.divider),
                const SizedBox(height: 10),

                // Formatting Toolbar Row
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Note Content Text Area
                SizedBox(
                  height: 200,
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
                const SizedBox(height: 14),

                // Footer Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bấm "_" hoặc Ctrl+N để thu gọn và vừa xem Chat vừa gõ',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7)),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: widget.onClose,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: Text(strings.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(strings.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

