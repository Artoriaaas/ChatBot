import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/reader/widgets/selection_menu.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/shared/widgets/math_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;

class ReaderPane extends StatefulWidget {
  final AppStrings strings;
  final Paper paper;
  final PaperPage? pageContent;
  final int currentPage;
  final bool isContinuousMode;
  final ValueChanged<int> onPageChanged;
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
    required this.paper,
    this.pageContent,
    required this.currentPage,
    required this.isContinuousMode,
    required this.onPageChanged,
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
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = [];
  OverlayEntry? _overlayEntry;
  String _currentSelection = '';

  @override
  void initState() {
    super.initState();
    _syncKeys();
    if (widget.isContinuousMode && widget.currentPage > 0) {
      _scrollToSection(widget.currentPage);
    }
  }

  @override
  void didUpdateWidget(ReaderPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (widget.isContinuousMode && widget.currentPage != oldWidget.currentPage) {
      _scrollToSection(widget.currentPage);
    }
  }

  void _syncKeys() {
    while (_sectionKeys.length < widget.paper.pages.length) {
      _sectionKeys.add(GlobalKey());
    }
  }

  void _scrollToSection(int index) {
    if (!widget.isContinuousMode) return;
    if (index >= 0 && index < _sectionKeys.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final keyContext = _sectionKeys[index].currentContext;
        if (keyContext != null) {
          Scrollable.ensureVisible(
            keyContext,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

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
    _scrollController.dispose();
    super.dispose();
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(AppColorsExtension colors, double baseFontSize) {
    return MarkdownStyleSheet(
      p: AppTypography.body.copyWith(
        fontSize: baseFontSize,
        height: 1.65,
        color: colors.textPrimary,
      ),
      pPadding: const EdgeInsets.only(bottom: 14),
      h1: AppTypography.heading1.copyWith(
        fontSize: baseFontSize * 1.4,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      h2: AppTypography.heading2.copyWith(
        fontSize: baseFontSize * 1.25,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      h3: AppTypography.subtitle.copyWith(
        fontSize: baseFontSize * 1.12,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      listBullet: AppTypography.body.copyWith(
        fontSize: baseFontSize,
        color: colors.textPrimary,
      ),
      code: AppTypography.code.copyWith(
        fontSize: baseFontSize * 0.9,
        backgroundColor: colors.surfaceElevated,
        color: colors.primary,
      ),
      blockquote: AppTypography.body.copyWith(
        fontSize: baseFontSize,
        fontStyle: FontStyle.italic,
        color: colors.textSecondary,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
    );
  }

  Widget _buildSectionWidget({
    required PaperPage page,
    required int index,
    required AppColorsExtension colors,
    required double baseFontSize,
    required MarkdownStyleSheet styleSheet,
    Key? key,
  }) {
    final textContent = page.content;

    Widget textWidget = MarkdownBody(
      data: textContent,
      selectable: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [MathSyntax()],
      builders: {'math': MathBuilder(textStyle: AppTypography.body.copyWith(color: colors.textPrimary))},
      styleSheet: styleSheet,
    );

    if (widget.highlightedCitationText != null &&
        textContent.contains(widget.highlightedCitationText!)) {
      textWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.highlightBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.onHighlight.withValues(alpha: 0.4)),
        ),
        child: textWidget,
      );
    } else if (widget.searchQuery.isNotEmpty &&
        textContent.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
      textWidget = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.selectionBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: textWidget,
      );
    }

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${index + 1}',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: baseFontSize * 0.75,
                    color: colors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  page.sectionTitle,
                  style: AppTypography.heading2.copyWith(
                    fontSize: baseFontSize * 1.35,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          textWidget,
          const SizedBox(height: 20),
          Divider(height: 1, color: colors.divider.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final baseFontSize = 14.5 * widget.zoomLevel;
    final styleSheet = _buildMarkdownStyleSheet(colors, baseFontSize);

    final pages = widget.paper.pages;
    final effectivePage = widget.pageContent ?? (pages.isNotEmpty ? pages[widget.currentPage.clamp(0, pages.length - 1)] : null);

    return Container(
      color: colors.appBackground,
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
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
                  // Paper Header
                  Container(
                    margin: const EdgeInsets.only(bottom: 28),
                    padding: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.divider, width: 1.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.paper.title,
                          style: AppTypography.heading1.copyWith(
                            fontSize: baseFontSize * 1.5,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (widget.paper.authors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: colors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.paper.authors.join(', '),
                                  style: AppTypography.caption.copyWith(
                                    fontSize: baseFontSize * 0.85,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (widget.paper.year > 0)
                                Text(
                                  '(${widget.paper.year})',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: baseFontSize * 0.85,
                                    color: colors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Continuous Mode: Display all sections in order
                  if (widget.isContinuousMode) ...[
                    for (int i = 0; i < pages.length; i++)
                      _buildSectionWidget(
                        page: pages[i],
                        index: i,
                        colors: colors,
                        baseFontSize: baseFontSize,
                        styleSheet: styleSheet,
                        key: i < _sectionKeys.length ? _sectionKeys[i] : null,
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '— ${widget.strings.endOfDocument} —',
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ]

                  // Paged Mode: Display only the selected section with bottom navigation
                  else if (effectivePage != null) ...[
                    _buildSectionWidget(
                      page: effectivePage,
                      index: widget.currentPage,
                      colors: colors,
                      baseFontSize: baseFontSize,
                      styleSheet: styleSheet,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.currentPage > 0)
                          OutlinedButton.icon(
                            onPressed: () => widget.onPageChanged(widget.currentPage - 1),
                            icon: const Icon(Icons.arrow_back, size: 14),
                            label: Text(
                              '${widget.strings.prevSection}: ${pages[widget.currentPage - 1].sectionTitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Text(
                          widget.strings.pageIndicator(widget.currentPage + 1, pages.length),
                          style: AppTypography.caption.copyWith(color: colors.textSecondary),
                        ),
                        if (widget.currentPage < pages.length - 1)
                          ElevatedButton.icon(
                            onPressed: () => widget.onPageChanged(widget.currentPage + 1),
                            icon: const Icon(Icons.arrow_forward, size: 14),
                            label: Text(
                              '${widget.strings.nextSection}: ${pages[widget.currentPage + 1].sectionTitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
