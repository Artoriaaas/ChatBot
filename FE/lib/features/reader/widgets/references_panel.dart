import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/document_reference.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferencesPanel extends StatefulWidget {
  final SettingsViewModel settingsVM;
  final Paper paper;
  final VoidCallback onClose;
  final void Function(DocumentReference ref)? onJumpToCitation;
  final Future<void> Function()? onReload;

  const ReferencesPanel({
    super.key,
    required this.settingsVM,
    required this.paper,
    required this.onClose,
    this.onJumpToCitation,
    this.onReload,
  });

  @override
  State<ReferencesPanel> createState() => _ReferencesPanelState();
}

class _ReferencesPanelState extends State<ReferencesPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _ensureReferencesAvailable();
  }

  void _ensureReferencesAvailable() {
    if (widget.paper.references.isEmpty) {
      _extractReferencesFromPages();
    }
    if (widget.paper.references.isEmpty && widget.onReload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleReload();
      });
    }
  }

  void _extractReferencesFromPages() {
    if (widget.paper.references.isNotEmpty) return;
    for (final page in widget.paper.pages) {
      final t = page.sectionTitle.toLowerCase();
      if (t.contains('reference') || t.contains('tài liệu tham khảo') || t.contains('bibliography')) {
        final parsed = DocumentReference.parseFromText(page.content);
        if (parsed.isNotEmpty) {
          widget.paper.references = parsed;
          if (mounted) setState(() {});
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentReference> _getFilteredReferences() {
    if (widget.paper.references.isEmpty) {
      _extractReferencesFromPages();
    }
    final allRefs = widget.paper.references;
    if (_filterQuery.trim().isEmpty) {
      return allRefs;
    }
    final q = _filterQuery.trim().toLowerCase();
    return allRefs.where((ref) {
      final titleMatch = ref.title?.toLowerCase().contains(q) ?? false;
      final authorsMatch = ref.authors?.toLowerCase().contains(q) ?? false;
      final yearMatch = ref.year?.toString().contains(q) ?? false;
      final venueMatch = ref.venue?.toLowerCase().contains(q) ?? false;
      final labelMatch = ref.label.toLowerCase().contains(q);
      final rawMatch = ref.rawCitationText?.toLowerCase().contains(q) ?? false;
      return titleMatch || authorsMatch || yearMatch || venueMatch || labelMatch || rawMatch;
    }).toList();
  }

  void _copyCitationToClipboard(DocumentReference ref) {
    final buffer = StringBuffer();
    if (ref.authors != null && ref.authors!.isNotEmpty) {
      buffer.write('${ref.authors}. ');
    }
    if (ref.year != null) {
      buffer.write('(${ref.year}). ');
    }
    if (ref.title != null && ref.title!.isNotEmpty) {
      buffer.write('"${ref.title}". ');
    }
    if (ref.venue != null && ref.venue!.isNotEmpty) {
      buffer.write('${ref.venue}. ');
    }
    if (ref.doi != null && ref.doi!.isNotEmpty) {
      buffer.write('https://doi.org/${ref.doi}');
    } else if (ref.url != null && ref.url!.isNotEmpty) {
      buffer.write(ref.url);
    } else if (buffer.isEmpty && ref.rawCitationText != null) {
      buffer.write(ref.rawCitationText);
    }

    final citationText = buffer.toString().trim();
    if (citationText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: citationText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.settingsVM.strings.citationCopied),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReload() async {
    if (widget.onReload == null || _isReloading) return;
    setState(() => _isReloading = true);
    try {
      await widget.onReload!();
    } finally {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: widget.settingsVM,
      builder: (context, _) {
        final strings = widget.settingsVM.strings;
        final filteredList = _getFilteredReferences();
        final totalCount = widget.paper.references.length;

        return Container(
          color: colors.sidebarBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Panel Header
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.sidebarBackground,
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_quote_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      strings.referencesHeader,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalCount',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.onReload != null)
                      IconButton(
                        icon: _isReloading
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary,
                                ),
                              )
                            : Icon(Icons.refresh_rounded, size: 16, color: colors.textSecondary),
                        onPressed: _handleReload,
                        tooltip: strings.refreshReferences,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
                      onPressed: widget.onClose,
                      tooltip: strings.closeReferences,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.divider),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _filterQuery = val);
                    },
                    style: AppTypography.caption.copyWith(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                    ),
                    decoration: InputDecoration(
                      hintText: strings.searchReferencesHint,
                      hintStyle: AppTypography.caption.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(Icons.search, size: 16, color: colors.textSecondary),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      suffixIcon: _filterQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filterQuery = '');
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),

              // Search Count Indicator (when searching)
              if (_filterQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                  child: Text(
                    '${strings.searchMatchIndicator(filteredList.length, totalCount)} ${strings.references.toLowerCase()}',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ),

              // List of References
              Expanded(
                child: totalCount == 0
                    ? _buildEmptyState(strings, colors, isSearch: false)
                    : filteredList.isEmpty
                        ? _buildEmptyState(strings, colors, isSearch: true)
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final ref = filteredList[index];
                              return _buildReferenceCard(ref, colors, strings, index);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferenceCard(
    DocumentReference ref,
    AppColorsExtension colors,
    dynamic strings,
    int index,
  ) {
    final effectiveUrl = ref.effectiveUrl;
    final label = ref.label.isNotEmpty ? ref.label : '${index + 1}';
    final hasTitle = ref.title != null && ref.title!.trim().isNotEmpty;
    final displayTitle = hasTitle ? ref.title!.trim() : (ref.rawCitationText ?? 'Trích dẫn [$label]');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: [Label badge] + [Year pill] + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[$label]',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (ref.year != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${ref.year}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Spacer(),

              // Quick Action: Copy Citation
              Tooltip(
                message: strings.copyCitation,
                child: InkWell(
                  onTap: () => _copyCitationToClipboard(ref),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded, size: 14, color: colors.textSecondary),
                  ),
                ),
              ),

              // Quick Action: Find in paper
              if (widget.onJumpToCitation != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: strings.jumpToCitationMention,
                  child: InkWell(
                    onTap: () => widget.onJumpToCitation!(ref),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.search_rounded, size: 15, color: colors.textSecondary),
                    ),
                  ),
                ),
              ],

              // Quick Action: Open external URL
              if (effectiveUrl.isNotEmpty) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: strings.openReferenceLink,
                  child: InkWell(
                    onTap: () {
                      final uri = Uri.tryParse(effectiveUrl);
                      if (uri != null) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.open_in_new_rounded, size: 14, color: colors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            displayTitle,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.35,
              color: colors.textPrimary,
            ),
          ),

          // Authors
          if (ref.authors != null && ref.authors!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_outline_rounded, size: 13, color: colors.textSecondary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    ref.authors!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Venue
          if (ref.venue != null && ref.venue!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book_outlined, size: 13, color: colors.textSecondary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    ref.venue!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // DOI / arXiv / URL Chip
          if (ref.isArxiv) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                final uri = Uri.tryParse(effectiveUrl);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 13, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'arXiv:${ref.arxivId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 11, color: Colors.redAccent),
                  ],
                ),
              ),
            ),
          ] else if (ref.doi != null && ref.doi!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                final uri = Uri.tryParse(effectiveUrl);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, size: 13, color: colors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'DOI: ${ref.doi!.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 11, color: colors.primary),
                  ],
                ),
              ),
            ),
          ] else if (effectiveUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                final uri = Uri.tryParse(effectiveUrl);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, size: 13, color: colors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        effectiveUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 11, color: colors.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(dynamic strings, AppColorsExtension colors, {required bool isSearch}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.library_books_outlined,
              size: 36,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isSearch ? strings.noReferencesFound : strings.noReferencesInPaper,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            if (!isSearch && widget.onReload != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _handleReload,
                icon: const Icon(Icons.refresh, size: 14),
                label: Text(strings.refreshReferences),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: AppTypography.caption,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
