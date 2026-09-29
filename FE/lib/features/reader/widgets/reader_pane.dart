import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/reader/widgets/selection_menu.dart';
import 'package:paper_chat/models/document_reference.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/shared/widgets/math_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

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
    if (widget.isContinuousMode &&
        (widget.currentPage != oldWidget.currentPage ||
            (widget.highlightedCitationText != null &&
                widget.highlightedCitationText != oldWidget.highlightedCitationText))) {
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

  void _handleLinkTap(String text, String? href, AppColorsExtension colors) {
    if (href == null || href.isEmpty) return;

    if (href.startsWith('cite:')) {
      final refKey = href.substring(5).trim();
      _showCitationDialog(refKey, text, colors);
      return;
    }

    if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('mailto:')) {
      final uri = Uri.tryParse(href);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (href.startsWith('#')) {
      _scrollToReferencesSection();
      return;
    }
  }

  void _scrollToReferencesSection() {
    int refSectionIndex = -1;
    for (int i = 0; i < widget.paper.pages.length; i++) {
      final t = widget.paper.pages[i].sectionTitle.toLowerCase();
      if (t.contains('reference') || t.contains('tài liệu tham khảo')) {
        refSectionIndex = i;
        break;
      }
    }
    if (refSectionIndex != -1) {
      if (widget.isContinuousMode) {
        _scrollToSection(refSectionIndex);
      } else {
        widget.onPageChanged(refSectionIndex);
      }
    }
  }

  void _showCitationDialog(String refKey, String displayText, AppColorsExtension colors) {
    final clean = refKey.trim().toLowerCase();
    final normalized = clean.replaceAll(RegExp(r'^[#b]+'), '');
    final cleanDisplay = displayText.trim().replaceAll(RegExp(r'[\[\]]'), '').toLowerCase();
    DocumentReference? ref;
    for (final r in widget.paper.references) {
      final refLower = r.refKey.toLowerCase();
      final k = refLower.replaceAll(RegExp(r'^[#b]+'), '');
      if (refLower == clean ||
          refLower == 'b$clean' ||
          r.label.toLowerCase() == clean ||
          r.label.toLowerCase() == cleanDisplay ||
          (normalized.isNotEmpty && k == normalized)) {
        ref = r;
        break;
      }
    }

    final citationLabel = ref?.label ?? displayText.trim().replaceAll(RegExp(r'[\[\]]'), '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        final effectiveUrl = ref?.effectiveUrl ?? '';
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.divider),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge + title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '[$citationLabel]',
                        style: AppTypography.heading3.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ref?.title ?? (ref != null ? 'Tài liệu tham khảo' : 'Trích dẫn [$citationLabel]'),
                        style: AppTypography.heading3.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: colors.textSecondary,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: colors.divider),
                const SizedBox(height: 16),

                if (ref != null) ...[
                  if (ref.authors != null && ref.authors!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 16, color: colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ref.authors!,
                            style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if ((ref.venue != null && ref.venue!.isNotEmpty) || ref.year != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 16, color: colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [
                              if (ref.venue != null && ref.venue!.isNotEmpty) ref.venue!,
                              if (ref.year != null) '(${ref.year})',
                            ].join(' '),
                            style: AppTypography.body.copyWith(
                              color: colors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ref.doi != null && ref.doi!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.link_rounded, size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DOI: ${ref.doi}',
                            style: AppTypography.caption.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ref.rawCitationText != null && ref.rawCitationText!.isNotEmpty && ref.title == null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.appBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        ref.rawCitationText!,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.appBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: colors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chưa có dữ liệu chi tiết cho trích dẫn này (có thể tài liệu được bóc tách bằng chế độ dự phòng iText7 hoặc bài báo cũ).',
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _scrollToReferencesSection();
                      },
                      icon: const Icon(Icons.library_books_outlined, size: 16),
                      label: const Text('Xem trong bài báo'),
                    ),
                    if (effectiveUrl.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          final uri = Uri.tryParse(effectiveUrl);
                          if (uri != null) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Mở liên kết'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
        color: colors.primary.withValues(alpha: 0.04),
        border: Border(left: BorderSide(color: colors.primary, width: 3.5)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      tableHead: AppTypography.caption.copyWith(
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      tableBody: AppTypography.body.copyWith(
        fontSize: baseFontSize * 0.95,
        color: colors.textPrimary,
      ),
      tableBorder: TableBorder.all(
        color: colors.divider,
        width: 1,
      ),
      strong: AppTypography.body.copyWith(
        fontSize: baseFontSize,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      em: AppTypography.body.copyWith(
        fontSize: baseFontSize,
        fontStyle: FontStyle.italic,
        color: colors.textPrimary,
      ),
      a: AppTypography.body.copyWith(
        fontSize: baseFontSize,
        color: colors.primary,
        decoration: TextDecoration.underline,
        decorationColor: colors.primary.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
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
      inlineSyntaxes: [
        BlockMathSyntax(),
        MathSyntax(),
      ],
      builders: {
        'math': MathBuilder(textStyle: AppTypography.body.copyWith(color: colors.textPrimary)),
        'math-block': MathBlockBuilder(textStyle: AppTypography.body.copyWith(color: colors.textPrimary)),
      },
      styleSheet: styleSheet,
      onTapLink: (text, href, title) {
        _handleLinkTap(text, href, colors);
      },
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
                          Flexible(
                            child: OutlinedButton(
                              onPressed: () => widget.onPageChanged(widget.currentPage - 1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back, size: 14),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${widget.strings.prevSection}: ${pages[widget.currentPage - 1].sectionTitle}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            widget.strings.pageIndicator(widget.currentPage + 1, pages.length),
                            style: AppTypography.caption.copyWith(color: colors.textSecondary),
                          ),
                        ),
                        if (widget.currentPage < pages.length - 1)
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () => widget.onPageChanged(widget.currentPage + 1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${widget.strings.nextSection}: ${pages[widget.currentPage + 1].sectionTitle}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward, size: 14),
                                ],
                              ),
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
