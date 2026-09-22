import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/motion.dart';
import 'package:paper_chat/models/paper.dart';

class PaperCard extends StatefulWidget {
  final Paper paper;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onAddToProject;

  const PaperCard({
    super.key,
    required this.paper,
    required this.onTap,
    required this.onToggleFavorite,
    this.onAddToProject,
  });

  @override
  State<PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<PaperCard> {
  bool _isHovered = false;

  Color _getStatusColor(PaperStatus status, AppColorsExtension colors) {
    switch (status) {
      case PaperStatus.unread:
        return Colors.grey;
      case PaperStatus.reading:
        return colors.primary;
      case PaperStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          decoration: BoxDecoration(
            color: _isHovered ? colors.highlightBackground : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? colors.primary.withValues(alpha: 0.5)
                  : colors.divider,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.paper.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onAddToProject != null && _isHovered)
                    Tooltip(
                      message: 'Thêm vào dự án',
                      child: InkWell(
                        onTap: widget.onAddToProject,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 12, color: colors.primary),
                              const SizedBox(width: 2),
                              Text(
                                'Dự án',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      widget.paper.isFavorite ? Icons.star : Icons.star_border,
                      color: widget.paper.isFavorite
                          ? Colors.amber
                          : colors.textSecondary,
                      size: 20,
                    ),
                    onPressed: widget.onToggleFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: widget.paper.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.paper.authorsShort} • ${widget.paper.year}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (widget.paper.indexStatus != 'Completed') ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: widget.paper.indexProgress / 100,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: colors.divider,
                        color: widget.paper.indexStatus == 'Failed'
                            ? Colors.red
                            : colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.paper.indexProgress}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.paper.indexStatus == 'Failed'
                      ? 'Chunking thất bại'
                      : widget.paper.indexStatus == 'Processing'
                      ? 'Đang chunking và tạo embedding...'
                      : 'Đang chờ xử lý...',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.paper.indexStatus == 'Failed'
                        ? Colors.red
                        : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(widget.paper.status, colors),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Text(
                      widget.paper.collection,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.paper.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.selectionBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSelection,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
