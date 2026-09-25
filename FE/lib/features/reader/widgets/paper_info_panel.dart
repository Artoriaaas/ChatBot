import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/reader/widgets/edit_paper_metadata_dialog.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/paper.dart';

class PaperInfoPanel extends StatefulWidget {
  final SettingsViewModel settingsVM;
  final Paper paper;
  final VoidCallback onClose;
  final ValueChanged<Paper>? onPaperUpdated;

  const PaperInfoPanel({
    super.key,
    required this.settingsVM,
    required this.paper,
    required this.onClose,
    this.onPaperUpdated,
  });

  @override
  State<PaperInfoPanel> createState() => _PaperInfoPanelState();
}

class _PaperInfoPanelState extends State<PaperInfoPanel> {
  void _openEditDialog() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditPaperMetadataDialog(
        paper: widget.paper,
        settingsVM: widget.settingsVM,
      ),
    );

    if (updated == true && mounted) {
      setState(() {});
      widget.onPaperUpdated?.call(widget.paper);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label vào bộ nhớ tạm'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: widget.settingsVM,
      builder: (context, _) {
        final strings = widget.settingsVM.strings;
        final paper = widget.paper;

        final hasJournal = paper.journal != null && paper.journal!.trim().isNotEmpty;
        final hasPublisher = paper.publisher != null && paper.publisher!.trim().isNotEmpty;
        final hasDoi = paper.doi != null && paper.doi!.trim().isNotEmpty;
        final hasVolume = paper.volume != null && paper.volume!.trim().isNotEmpty;
        final hasIssue = paper.issue != null && paper.issue!.trim().isNotEmpty;
        final hasPages = paper.pagesInfo != null && paper.pagesInfo!.trim().isNotEmpty;
        final hasKeywords = paper.keywords != null && paper.keywords!.trim().isNotEmpty;

        return Container(
          color: colors.sidebarBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.sidebarBackground,
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.paperInfo,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 15, color: colors.textSecondary),
                      onPressed: _openEditDialog,
                      tooltip: strings.editMetadata,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
                      onPressed: widget.onClose,
                      tooltip: 'Đóng',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Title
                    Text(
                      paper.title,
                      style: AppTypography.heading3.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Authors
                    _buildMetaRow(
                      icon: Icons.people_outline,
                      label: 'Tác giả',
                      value: paper.authors.isNotEmpty ? paper.authors.join(', ') : 'Chưa rõ tác giả',
                      colors: colors,
                    ),
                    const SizedBox(height: 10),

                    // Year
                    _buildMetaRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Năm xuất bản',
                      value: '${paper.year}',
                      colors: colors,
                    ),
                    const SizedBox(height: 10),

                    // Journal / Venue
                    if (hasJournal) ...[
                      _buildMetaRow(
                        icon: Icons.menu_book_outlined,
                        label: strings.journalOrVenue,
                        value: paper.journal!,
                        colors: colors,
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Publisher
                    if (hasPublisher) ...[
                      _buildMetaRow(
                        icon: Icons.business_outlined,
                        label: strings.publisherLabel,
                        value: paper.publisher!,
                        colors: colors,
                      ),
                      const SizedBox(height: 10),
                    ],

                    // DOI
                    if (hasDoi) ...[
                      _buildDoiRow(paper.doi!, colors),
                      const SizedBox(height: 10),
                    ],

                    // Volume / Issue / Pages
                    if (hasVolume || hasIssue || hasPages) ...[
                      _buildMetaRow(
                        icon: Icons.format_list_numbered,
                        label: 'Tập / Số / Trang',
                        value: [
                          if (hasVolume) 'Vol. ${paper.volume}',
                          if (hasIssue) 'No. ${paper.issue}',
                          if (hasPages) 'pp. ${paper.pagesInfo}',
                        ].join(' • '),
                        colors: colors,
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Keywords / Tags
                    if (hasKeywords || paper.tags.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.label_outline, size: 14, color: colors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.keywordsLabel,
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: (hasKeywords
                                          ? paper.keywords!.split(',')
                                          : paper.tags)
                                      .map((tag) => tag.trim())
                                      .where((tag) => tag.isNotEmpty)
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colors.surface,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: colors.divider),
                                          ),
                                          child: Text(
                                            tag,
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 11,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Divider
                    Divider(color: colors.divider, height: 16),

                    // Abstract
                    Text(
                      'Tóm tắt (Abstract)',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.divider),
                      ),
                      child: SelectableText(
                        paper.abstractText.isNotEmpty
                            ? paper.abstractText
                            : 'Chưa có thông tin tóm tắt bài báo.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          height: 1.45,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status and Info Chips
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: paper.indexStatus == 'Completed'
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            paper.indexStatus == 'Completed' ? 'Đã lập chỉ mục' : paper.indexStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: paper.indexStatus == 'Completed' ? Colors.green : Colors.amber.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${paper.totalPages} phần nội dung',
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Edit button
                    OutlinedButton.icon(
                      onPressed: _openEditDialog,
                      icon: const Icon(Icons.edit, size: 14),
                      label: Text(strings.editMetadata),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required dynamic colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: colors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoiRow(String doi, dynamic colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.link, size: 14, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOI',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      doi,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: colors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 13, color: colors.textSecondary),
                    onPressed: () => _copyToClipboard(doi, 'DOI'),
                    tooltip: 'Sao chép DOI',
                    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
