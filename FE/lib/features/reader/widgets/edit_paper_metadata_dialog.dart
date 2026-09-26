import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/api_service.dart';
import 'package:paper_chat/services/doi_service.dart';
import 'package:paper_chat/services/settings_repository.dart';

class EditPaperMetadataDialog extends StatefulWidget {
  final Paper paper;
  final SettingsViewModel? settingsVM;

  const EditPaperMetadataDialog({
    super.key,
    required this.paper,
    this.settingsVM,
  });

  @override
  State<EditPaperMetadataDialog> createState() => _EditPaperMetadataDialogState();
}

class _EditPaperMetadataDialogState extends State<EditPaperMetadataDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _yearController;
  late final TextEditingController _journalController;
  late final TextEditingController _publisherController;
  late final TextEditingController _doiController;
  late final TextEditingController _volumeController;
  late final TextEditingController _issueController;
  late final TextEditingController _pagesController;
  late final TextEditingController _keywordsController;
  late final TextEditingController _abstractController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.paper;
    _titleController = TextEditingController(text: p.title);
    _authorsController = TextEditingController(text: p.authors.join(', '));
    _yearController = TextEditingController(text: '${p.year}');
    _journalController = TextEditingController(text: p.journal ?? '');
    _publisherController = TextEditingController(text: p.publisher ?? '');
    _doiController = TextEditingController(text: p.doi ?? '');
    _volumeController = TextEditingController(text: p.volume ?? '');
    _issueController = TextEditingController(text: p.issue ?? '');
    _pagesController = TextEditingController(text: p.pagesInfo ?? '');
    _keywordsController = TextEditingController(
      text: (p.keywords != null && p.keywords!.isNotEmpty)
          ? p.keywords
          : p.tags.join(', '),
    );
    _abstractController = TextEditingController(text: p.abstractText);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _yearController.dispose();
    _journalController.dispose();
    _publisherController.dispose();
    _doiController.dispose();
    _volumeController.dispose();
    _issueController.dispose();
    _pagesController.dispose();
    _keywordsController.dispose();
    _abstractController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Tiêu đề không được để trống.');
      return;
    }

    final year = int.tryParse(_yearController.text.trim()) ?? widget.paper.year;
    final authorsList = _authorsController.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    final keywords = _keywordsController.text.trim();
    final tagsList = keywords.isNotEmpty
        ? keywords.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : widget.paper.tags;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final intId = int.tryParse(widget.paper.id);
      if (intId != null) {
        final apiService = ApiService();
        await apiService.updatePaper(intId, {
          'id': intId,
          'title': title,
          'authors': authorsList.isNotEmpty ? authorsList.join(', ') : 'Chưa rõ tác giả',
          'year': year,
          'abstractText': _abstractController.text.trim(),
          'collection': widget.paper.collection,
          'tags': tagsList.join(', '),
          'journal': _journalController.text.trim().isEmpty ? null : _journalController.text.trim(),
          'publisher': _publisherController.text.trim().isEmpty ? null : _publisherController.text.trim(),
          'doi': _doiController.text.trim().isEmpty ? null : _doiController.text.trim(),
          'volume': _volumeController.text.trim().isEmpty ? null : _volumeController.text.trim(),
          'issue': _issueController.text.trim().isEmpty ? null : _issueController.text.trim(),
          'pages': _pagesController.text.trim().isEmpty ? null : _pagesController.text.trim(),
          'keywords': keywords.isEmpty ? null : keywords,
        });
      }

      // Update in-memory model
      widget.paper.updateMetadata(
        title: title,
        authors: authorsList.isNotEmpty ? authorsList : ['Chưa rõ tác giả'],
        year: year,
        abstractText: _abstractController.text.trim(),
        tags: tagsList,
        journal: _journalController.text.trim().isEmpty ? null : _journalController.text.trim(),
        publisher: _publisherController.text.trim().isEmpty ? null : _publisherController.text.trim(),
        doi: _doiController.text.trim().isEmpty ? null : _doiController.text.trim(),
        volume: _volumeController.text.trim().isEmpty ? null : _volumeController.text.trim(),
        issue: _issueController.text.trim().isEmpty ? null : _issueController.text.trim(),
        pagesInfo: _pagesController.text.trim().isEmpty ? null : _pagesController.text.trim(),
        keywords: keywords.isEmpty ? null : keywords,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Lỗi lưu dữ liệu: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.settingsVM?.strings ?? AppStrings(AppLanguage.vi);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Bar
              Row(
                children: [
                  Icon(Icons.edit_note, size: 22, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.editMetadata,
                      style: AppTypography.heading3.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop(false);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: colors.divider, height: 1),
              const SizedBox(height: 12),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],

              // Form fields
              Expanded(
                child: ListView(
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Tiêu đề bài báo *',
                      colors: colors,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _authorsController,
                      label: 'Tác giả (ngăn cách bằng dấu phẩy)',
                      colors: colors,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _yearController,
                            label: 'Năm xuất bản',
                            colors: colors,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _doiController,
                            label: 'DOI (vd: 10.1109/...)',
                            colors: colors,
                            suffixIcon: Tooltip(
                              message: 'Mở liên kết DOI trong trình duyệt',
                              child: IconButton(
                                icon: Icon(Icons.open_in_new, size: 16, color: colors.primary),
                                onPressed: () async {
                                  final text = _doiController.text.trim();
                                  if (text.isEmpty) return;
                                  final success = await DoiService.openDoi(text);
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Không thể mở liên kết DOI'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _journalController,
                            label: 'Tạp chí / Hội nghị (Journal / Venue)',
                            colors: colors,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _publisherController,
                            label: 'Nhà xuất bản (Publisher)',
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _volumeController,
                            label: 'Tập (Volume)',
                            colors: colors,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            controller: _issueController,
                            label: 'Số (Issue)',
                            colors: colors,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            controller: _pagesController,
                            label: 'Trang (vd: 1–12)',
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _keywordsController,
                      label: 'Từ khóa (Keywords, cách nhau bằng dấu phẩy)',
                      colors: colors,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _abstractController,
                      label: 'Tóm tắt (Abstract)',
                      colors: colors,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: colors.divider, height: 1),
              const SizedBox(height: 12),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop(false);
                            }
                          },
                    child: Text('Hủy', style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required dynamic colors,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.caption.copyWith(
            fontSize: 13,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: colors.appBackground,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
