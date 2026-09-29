import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/services/doi_service.dart';
import 'package:paper_chat/shared/widgets/math_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatefulWidget {
  final AppStrings strings;
  final ChatMessage message;
  final void Function(int page, String excerpt) onCitationTap;
  final VoidCallback onSaveNote;
  final VoidCallback onRetry;

  const MessageBubble({
    super.key,
    required this.strings,
    required this.message,
    required this.onCitationTap,
    required this.onSaveNote,
    required this.onRetry,
  });

  /// Chuyển đổi các chỉ số trích dẫn [1], [2], [1][2]... thành markdown link tương tác được
  static String transformCitationsToMarkdownLinks(String raw) {
    if (raw.isEmpty) return raw;
    final regex = RegExp(r'(?<!\[)\[(\d+)\](?!\()');
    return raw.replaceAllMapped(regex, (match) {
      final num = match.group(1);
      return '[\\[$num\\]](cite-source:$num)';
    });
  }

  /// Làm sạch các cú pháp Markdown thô và cú pháp cite nội bộ khi hiển thị trích đoạn ngắn
  static String cleanExcerptForDisplay(String raw) {
    if (raw.isEmpty) return raw;
    String clean = raw;
    // 1. Chuyển đổi cú pháp cite kỹ thuật: [\[1\]](cite:b0) -> [1] hoặc [1](cite:b0) -> [1]
    clean = clean.replaceAllMapped(
      RegExp(r'\[(?:\\\[)?(\d+)(?:\\\])?\]\(cite:[^\)]+\)'),
      (m) => '[${m.group(1)}]',
    );
    // 2. Chuyển các heading dòng đơn '# ' hoặc '## ' thành in đậm '**...**'
    clean = clean.replaceAllMapped(
      RegExp(r'^(#{1,3})\s+(.+)$', multiLine: true),
      (m) => '**${m.group(2)}**',
    );
    return clean.trim();
  }

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  static const int _verticalReferenceThreshold = 8;

  int _selectedCitationIndex = 0;
  bool _isReferencesExpanded = true;
  final ScrollController _referenceTabsController = ScrollController();
  final ScrollController _referenceListController = ScrollController();
  bool _canScrollReferencesLeft = false;
  bool _canScrollReferencesRight = true;

  @override
  void initState() {
    super.initState();
    _referenceTabsController.addListener(_updateReferenceScrollButtons);
  }

  void _updateReferenceScrollButtons() {
    if (!_referenceTabsController.hasClients) return;

    final position = _referenceTabsController.position;
    final canScrollLeft = position.pixels > 1;
    final canScrollRight = position.pixels < position.maxScrollExtent - 1;
    if (canScrollLeft != _canScrollReferencesLeft ||
        canScrollRight != _canScrollReferencesRight) {
      setState(() {
        _canScrollReferencesLeft = canScrollLeft;
        _canScrollReferencesRight = canScrollRight;
      });
    }
  }

  void _scrollReferences(bool forward) {
    if (!_referenceTabsController.hasClients) return;

    final position = _referenceTabsController.position;
    final distance = position.viewportDimension * 0.75;
    final target = (position.pixels + (forward ? distance : -distance)).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _referenceTabsController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _referenceTabsController
      ..removeListener(_updateReferenceScrollButtons)
      ..dispose();
    _referenceListController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _selectedCitationIndex = 0;
      if (_referenceTabsController.hasClients) {
        _referenceTabsController.jumpTo(0);
      }
    }
    if (_selectedCitationIndex >= widget.message.citations.length) {
      _selectedCitationIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isUser = widget.message.role == MessageRole.user;
    final formattedTime =
        '${widget.message.timestamp.hour.toString().padLeft(2, '0')}:${widget.message.timestamp.minute.toString().padLeft(2, '0')}';

    if (isUser) {
      // User Message: Aligned to the RIGHT
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // User Header (Name & Time aligned right)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  formattedTime,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.strings.userRole,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'B',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Quoted text context if user selected text before asking
            if (widget.message.selectedText != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    right: BorderSide(color: colors.primary, width: 3),
                  ),
                ),
                child: Text(
                  '"${widget.message.selectedText!}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.textSecondary,
                  ),
                ),
              ),

            // User Message Bubble Container
            Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.selectionBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                widget.message.content,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Assistant Message: Aligned to the LEFT
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Header (Avatar, Assistant Name, Time)
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 13,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.strings.assistantRole,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                formattedTime,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // AI Message Content Body (Left padded)
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data:
                      MessageBubble.transformCitationsToMarkdownLinks(
                        widget.message.content,
                      ) +
                      (widget.message.isStreaming ? ' ▋' : ''),
                  selectable: true,
                  extensionSet: md.ExtensionSet.gitHubFlavored,
                  inlineSyntaxes: [MathSyntax()],
                  builders: {
                    'math': MathBuilder(
                      textStyle: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  },
                  onTapLink: (text, href, title) async {
                    if (href == null || href.isEmpty) return;
                    if (href.startsWith('cite-source:')) {
                      final idxStr = href.substring('cite-source:'.length);
                      final sourceIdx = int.tryParse(idxStr);
                      if (sourceIdx != null) {
                        _showCitationPreviewDialog(context, sourceIdx, colors);
                      }
                      return;
                    }
                    if (DoiService.isValidDoi(href)) {
                      await DoiService.openDoi(href);
                    } else {
                      final uri = Uri.tryParse(href);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      height: 1.5,
                    ),
                    h1: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: AppTypography.caption.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                    strong: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    em: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                    a: AppTypography.body.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    code: AppTypography.code.copyWith(
                      backgroundColor: colors.surfaceElevated,
                      color: colors.primary,
                    ),
                  ),
                ),

                // Modern Source References Section at bottom of AI answer
                if (widget.message.citations.isNotEmpty) ...[
                  _buildModernReferencesSection(colors),
                ],

                // Action Row: Copy & Save Note
                if (!widget.message.isStreaming && !widget.message.isError) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.message.content),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.strings.copiedToClipboard),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.copy_outlined,
                                size: 13,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.strings.copy,
                                style: AppTypography.caption.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: widget.onSaveNote,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bookmark_outline,
                                size: 13,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.strings.saveNote,
                                style: AppTypography.caption.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (widget.message.isError) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: widget.onRetry,
                    icon: Icon(Icons.refresh, size: 14, color: colors.error),
                    label: Text(
                      widget.strings.retry,
                      style: AppTypography.caption.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng khối Source References hiện đại, thanh lịch, có thể chuyển đổi giữa các nguồn
  Widget _buildModernReferencesSection(AppColorsExtension colors) {
    final citations = widget.message.citations;
    final safeIndex = _selectedCitationIndex.clamp(0, citations.length - 1);
    final activeCitation = citations[safeIndex];
    final cleanContent = MessageBubble.cleanExcerptForDisplay(
      activeCitation.excerpt,
    );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar: Icon, Title & Expand/Collapse Toggle
          InkWell(
            onTap: () =>
                setState(() => _isReferencesExpanded = !_isReferencesExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 14,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.strings.isVi
                        ? 'Nguồn trích dẫn (${citations.length})'
                        : 'Source References (${citations.length})',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isReferencesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          if (_isReferencesExpanded) ...[
            const Divider(height: 1),
            _buildReferenceSelector(colors, citations, safeIndex),

            // Active Excerpt Card Container
            Container(
              margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.divider.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Name & Section info
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          activeCitation.fileName ??
                              (widget.strings.isVi
                                  ? 'Tài liệu nguồn'
                                  : 'Source Document'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Excerpt Rich Text via MarkdownBody (Formatted, NOT plain italic text!)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 130),
                    child: SingleChildScrollView(
                      child: MarkdownBody(
                        data: cleanContent,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: colors.textPrimary,
                            height: 1.45,
                          ),
                          strong: AppTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          em: AppTypography.caption.copyWith(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: colors.textPrimary,
                          ),
                          code: AppTypography.code.copyWith(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Actions: Copy & Jump to Document
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: activeCitation.excerpt),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.strings.copiedToClipboard),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.copy_outlined,
                                size: 12,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.strings.copy,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => widget.onCitationTap(
                          activeCitation.page,
                          activeCitation.excerpt,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Text(
                                widget.strings.isVi
                                    ? 'Đến bài báo'
                                    : 'Jump to paper',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: colors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceSelector(
    AppColorsExtension colors,
    List<Citation> citations,
    int selectedIndex,
  ) {
    if (citations.length > _verticalReferenceThreshold) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: Scrollbar(
            controller: _referenceListController,
            thumbVisibility: true,
            interactive: true,
            child: ListView.separated(
              controller: _referenceListController,
              padding: const EdgeInsets.only(right: 10),
              itemCount: citations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) => _buildReferenceListItem(
                colors,
                citations[index],
                index,
                index == selectedIndex,
              ),
            ),
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateReferenceScrollButtons();
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _canScrollReferencesLeft
                ? () => _scrollReferences(false)
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            tooltip: widget.strings.isVi ? 'Nguồn trước' : 'Previous sources',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 32),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Scrollbar(
              controller: _referenceTabsController,
              thumbVisibility: true,
              interactive: true,
              thickness: 4,
              child: SingleChildScrollView(
                controller: _referenceTabsController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: List.generate(citations.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildReferenceTab(
                        colors,
                        citations[index],
                        index,
                        index == selectedIndex,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _canScrollReferencesRight
                ? () => _scrollReferences(true)
                : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            tooltip: widget.strings.isVi ? 'Nguồn tiếp theo' : 'Next sources',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceTab(
    AppColorsExtension colors,
    Citation citation,
    int index,
    bool isSelected,
  ) {
    final label = citation.label.isNotEmpty ? citation.label : '[${index + 1}]';
    final pageInfo = citation.page >= 0
        ? ' · ${widget.strings.isVi ? 'tr.' : 'p.'} ${citation.page + 1}'
        : '';

    return InkWell(
      onTap: () => setState(() => _selectedCitationIndex = index),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isSelected ? colors.onPrimary : colors.primary,
              ),
            ),
            if (pageInfo.isNotEmpty)
              Text(
                pageInfo,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: isSelected
                      ? colors.onPrimary.withValues(alpha: 0.85)
                      : colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceListItem(
    AppColorsExtension colors,
    Citation citation,
    int index,
    bool isSelected,
  ) {
    final label = citation.label.isNotEmpty ? citation.label : '[${index + 1}]';
    final pageLabel = citation.page >= 0
        ? '${widget.strings.isVi ? 'tr.' : 'p.'} ${citation.page + 1}'
        : null;

    return Material(
      color: isSelected
          ? colors.primary.withValues(alpha: 0.12)
          : colors.surface,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: () => setState(() => _selectedCitationIndex = index),
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected ? colors.primary : colors.divider,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ),
              if (pageLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  pageLabel,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị Dialog Popover xem trước trích đoạn gốc với Markdown chuẩn mực
  void _showCitationPreviewDialog(
    BuildContext context,
    int sourceIndex,
    AppColorsExtension colors,
  ) {
    Citation? citation;
    try {
      citation = widget.message.citations.firstWhere(
        (c) => c.sourceIndex == sourceIndex || c.label == '[$sourceIndex]',
      );
    } catch (_) {
      citation = null;
    }

    final cleanContent = citation != null
        ? MessageBubble.cleanExcerptForDisplay(citation.excerpt)
        : '';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.divider),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Nguồn [$sourceIndex]',
                          style: AppTypography.caption.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          citation?.fileName ??
                              (widget.strings.isVi
                                  ? 'Tài liệu nguồn'
                                  : 'Source Document'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (citation != null && cleanContent.isNotEmpty) ...[
                    Text(
                      widget.strings.isVi
                          ? 'Đoạn trích dẫn từ bài báo:'
                          : 'Excerpt from document:',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(color: colors.primary, width: 3),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: cleanContent,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTypography.body.copyWith(
                              fontSize: 13,
                              color: colors.textPrimary,
                              height: 1.45,
                            ),
                            strong: AppTypography.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            em: AppTypography.body.copyWith(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: colors.textPrimary,
                            ),
                            code: AppTypography.code.copyWith(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.strings.isVi
                            ? 'Trích dẫn này được mô hình AI tổng hợp từ ngữ cảnh bài báo.'
                            : 'This citation was synthesized by AI from the document context.',
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (citation != null && citation.excerpt.isNotEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: citation!.excerpt),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(widget.strings.copiedToClipboard),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined, size: 14),
                          label: Text(
                            widget.strings.copy,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (citation != null) ...[
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            widget.onCitationTap(
                              citation!.page,
                              citation.excerpt,
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_outward_rounded,
                            size: 14,
                          ),
                          label: Text(
                            widget.strings.isVi
                                ? 'Xem trong bài báo'
                                : 'Jump to document',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ] else ...[
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          child: Text(widget.strings.isVi ? 'Đóng' : 'Close'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
