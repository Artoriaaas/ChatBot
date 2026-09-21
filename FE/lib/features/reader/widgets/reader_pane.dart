import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/reader/widgets/selection_menu.dart';
import 'package:paper_chat/models/paper.dart';

class ReaderPane extends StatefulWidget {
  final AppStrings strings;
  final PaperPage pageContent;
  final double zoomLevel;
  final String searchQuery;
  final Set<String> highlights;
  final String? highlightedCitationText;
  final ValueChanged<String> onTextSelected;
  final VoidCallback onClearSelection;
  final VoidCallback onExplain;
  final VoidCallback onSummarize;
  final VoidCallback onAskAi;
  final VoidCallback onAddNote;
  final ValueChanged<String> onToggleHighlight;

  const ReaderPane({
    super.key,
    required this.strings,
    required this.pageContent,
    required this.zoomLevel,
    required this.searchQuery,
    required this.highlights,
    this.highlightedCitationText,
    required this.onTextSelected,
    required this.onClearSelection,
    required this.onExplain,
    required this.onSummarize,
    required this.onAskAi,
    required this.onAddNote,
    required this.onToggleHighlight,
  });

  @override
  State<ReaderPane> createState() => _ReaderPaneState();
}

class _ReaderPaneState extends State<ReaderPane> {
  OverlayEntry? _overlayEntry;
  String _currentSelection = '';

  void _showSelectionMenu(Rect rect) {
    _hideSelectionMenu();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: rect.top - 42,
          left: rect.left,
          child: SelectionMenu(
            strings: widget.strings,
            onExplain: () {
              widget.onExplain();
              _hideSelectionMenu();
            },
            onSummarize: () {
              widget.onSummarize();
              _hideSelectionMenu();
            },
            onAskAi: () {
              widget.onAskAi();
              _hideSelectionMenu();
            },
            onAddNote: () {
              widget.onAddNote();
              _hideSelectionMenu();
            },
            onHighlight: () {
              if (_currentSelection.isNotEmpty) {
                widget.onToggleHighlight(_currentSelection);
              }
              _hideSelectionMenu();
            },
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSelectionMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideSelectionMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final baseFontSize = 14.5 * widget.zoomLevel;

    return Container(
      color: colors.appBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 720 * widget.zoomLevel.clamp(0.8, 1.4),
              minHeight: 900 * widget.zoomLevel.clamp(0.8, 1.4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SelectionArea(
              onSelectionChanged: (content) {
                if (content != null && content.plainText.trim().isNotEmpty) {
                  _currentSelection = content.plainText.trim();
                  widget.onTextSelected(_currentSelection);

                  final renderBox = context.findRenderObject();
                  if (renderBox is RenderBox) {
                    final size = renderBox.size;
                    _showSelectionMenu(Rect.fromLTWH(size.width / 2, size.height / 3, 0, 0));
                  }
                } else {
                  _currentSelection = '';
                  widget.onClearSelection();
                  _hideSelectionMenu();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Section Title Header
                  Text(
                    widget.pageContent.sectionTitle,
                    style: AppTypography.heading2.copyWith(
                      fontSize: baseFontSize * 1.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Paper Page Main Body Content
                  Builder(builder: (context) {
                    final textContent = widget.pageContent.content;

                    Widget textWidget = Text(
                      textContent,
                      style: AppTypography.body.copyWith(
                        fontSize: baseFontSize,
                        height: 1.65,
                        color: colors.textPrimary,
                      ),
                    );

                    // Citation flash highlight container if targeted
                    if (widget.highlightedCitationText != null &&
                        textContent.contains(widget.highlightedCitationText!)) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.highlightBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.onHighlight.withValues(alpha: 0.4)),
                        ),
                        child: textWidget,
                      );
                    }

                    // Search match highlight container
                    if (widget.searchQuery.isNotEmpty &&
                        textContent.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.selectionBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                        ),
                        child: textWidget,
                      );
                    }

                    return textWidget;
                  }),
                  const SizedBox(height: 32),

                  // Page Footer Indicator
                  Divider(height: 1, color: colors.divider.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '— ${widget.strings.pageTag(widget.pageContent.pageNumber + 1)} —',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
