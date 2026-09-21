import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/models/note.dart';

class NoteCard extends StatefulWidget {
  final AppStrings strings;
  final Note note;
  final VoidCallback onNavigate;
  final VoidCallback onDelete;
  final Function(String) onUpdate;

  const NoteCard({
    super.key,
    required this.strings,
    required this.note,
    required this.onNavigate,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getRelativeTime(DateTime dateTime, AppStrings strings) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return strings.justNow;
    if (difference.inHours < 1) return strings.minAgo(difference.inMinutes);
    if (difference.inDays < 1) return strings.hoursAgo(difference.inHours);
    if (difference.inDays < 2) return strings.yesterday;
    return strings.daysAgo(difference.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.strings;

    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onNavigate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.note.paperTitle,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${strings.pageTag(widget.note.page + 1)} · ${widget.note.sectionTitle}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  _getRelativeTime(widget.note.createdAt, strings),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              TextField(
                controller: _controller,
                maxLines: null,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _controller.text = widget.note.content;
                      });
                    },
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onUpdate(_controller.text);
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    child: Text(strings.save),
                  ),
                ],
              ),
            ] else ...[
              Text(
                widget.note.content,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: strings.editNote,
                    color: colors.textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: strings.deleteNote,
                    color: colors.error,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
