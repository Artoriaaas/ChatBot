import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/models/paper.dart';

class ImportPaperDialog extends StatefulWidget {
  final AppStrings strings;
  final ValueChanged<Paper> onSave;

  const ImportPaperDialog({
    super.key,
    required this.strings,
    required this.onSave,
  });

  @override
  State<ImportPaperDialog> createState() => _ImportPaperDialogState();
}

class _ImportPaperDialogState extends State<ImportPaperDialog> {
  PlatformFile? _selectedFile;
  int _fileSizeBytes = 0;
  bool _isExtracting = false;
  bool _extractionComplete = false;

  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _collectionController = TextEditingController(text: 'Deep Learning');
  final _tagsController = TextEditingController(text: 'AI, LLM');
  final _abstractController = TextEditingController();
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _yearController.dispose();
    _collectionController.dispose();
    _tagsController.dispose();
    _abstractController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        dialogTitle: widget.strings.uploadPdfTitle,
      );

      if (result.isNotEmpty) {
        final file = result.first;
        int bytes = 0;
        try {
          final len = await file.length();
          bytes = len ?? 0;
        } catch (_) {
          try {
            final lenSync = file.lengthSync();
            bytes = lenSync ?? 0;
          } catch (_) {
            bytes = 0;
          }
        }

        setState(() {
          _selectedFile = file;
          _fileSizeBytes = bytes;
          _isExtracting = true;
          _extractionComplete = false;
        });

        // Simulate backend AI PDF extraction pipeline
        await Future.delayed(const Duration(milliseconds: 1000));

        // Format cleaned title from filename
        final rawName = file.name
            .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
            .replaceAll('_', ' ')
            .replaceAll('-', ' ');
        final cleanedTitle = rawName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
            .join(' ');

        if (mounted) {
          setState(() {
            _isExtracting = false;
            _extractionComplete = true;
            _titleController.text = cleanedTitle.isNotEmpty ? cleanedTitle : 'Tài liệu nghiên cứu mới';
            _authorsController.text = 'Extracted Researcher, AI Collaborator';
            _yearController.text = DateTime.now().year.toString();
            _collectionController.text = 'Tài liệu tải lên';
            _tagsController.text = 'PDF, AI Parsed';
            _abstractController.text =
                'Tài liệu được tải lên từ file "${file.name}" và đã được AI trích xuất nội dung, phân tích cấu trúc học thuật, sẵn sàng để đọc và đối thoại thông minh.';
            _titleError = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở file: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'PDF Document';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = widget.strings.titleRequired;
      });
      return;
    }

    final authorsList = _authorsController.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    final tagsList = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final year = int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;
    final collection = _collectionController.text.trim().isNotEmpty
        ? _collectionController.text.trim()
        : 'General';

    final fileName = _selectedFile?.name ?? '$title.pdf';
    final abstractText = _abstractController.text.trim().isNotEmpty
        ? _abstractController.text.trim()
        : 'Tài liệu nghiên cứu: $title.';

    final newPaper = Paper(
      id: 'paper_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      authors: authorsList.isNotEmpty ? authorsList : ['Research Author'],
      year: year,
      abstractText: abstractText,
      collection: collection,
      tags: tagsList.isNotEmpty ? tagsList : ['Research'],
      pages: [
        PaperPage(
          pageNumber: 1,
          sectionTitle: 'Tổng quan & Tóm tắt (Abstract)',
          content: '$abstractText\n\nToàn bộ văn bản và dữ liệu từ tệp "$fileName" đã được AI xử lý và phân tách thành các đoạn nội dung cho mô hình ngôn ngữ lớn (LLM).',
        ),
        PaperPage(
          pageNumber: 2,
          sectionTitle: 'Phương pháp & Nội dung cốt lõi',
          content: 'Trang 2: Chi tiết phương pháp nghiên cứu, thuật toán và dữ liệu thực nghiệm được trích xuất từ "$fileName".\n\nNgười dùng có thể đặt bất kỳ câu hỏi nào trong khung chat để AI trích dẫn và phân tích chuyên sâu.',
        ),
        PaperPage(
          pageNumber: 3,
          sectionTitle: 'Kết luận & Hướng phát triển',
          content: 'Trang 3: Đánh giá kết quả nghiên cứu, phân tích hạn chế và tài liệu tham khảo được hệ thống lập chỉ mục (Vector Indexing) phục vụ RAG (Retrieval-Augmented Generation).',
        ),
      ],
    );

    widget.onSave(newPaper);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.strings;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(Icons.picture_as_pdf_rounded, color: colors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.uploadPdfTitle,
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.uploadPdfSubtitle,
                          style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.divider),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PDF Upload Dropzone / File Picker Card
                    _buildUploadDropzone(colors, strings),
                    const SizedBox(height: 18),

                    // Section: Thông tin bài báo
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _selectedFile != null
                              ? 'Thông tin trích xuất từ file (Có thể chỉnh sửa)'
                              : 'Thông tin bài báo',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title Field
                    _buildFieldLabel(strings.paperTitleLabel, isRequired: true, colors: colors),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: strings.paperTitleHint,
                        hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.article_outlined, size: 18, color: colors.textSecondary),
                        errorText: _titleError,
                        filled: true,
                        fillColor: colors.appBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary)),
                      ),
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Authors & Year Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(strings.authorsLabel, colors: colors),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _authorsController,
                                style: AppTypography.body.copyWith(color: colors.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: strings.authorsHint,
                                  hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                                  prefixIcon: Icon(Icons.people_outline, size: 18, color: colors.textSecondary),
                                  filled: true,
                                  fillColor: colors.appBackground,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(strings.yearLabel, colors: colors),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                style: AppTypography.body.copyWith(color: colors.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: '2024',
                                  hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                                  filled: true,
                                  fillColor: colors.appBackground,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Collection & Tags Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(strings.collectionLabel, colors: colors),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _collectionController,
                                style: AppTypography.body.copyWith(color: colors.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: strings.collectionHint,
                                  hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                                  prefixIcon: Icon(Icons.folder_outlined, size: 18, color: colors.textSecondary),
                                  filled: true,
                                  fillColor: colors.appBackground,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(strings.tagsLabel, colors: colors),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _tagsController,
                                style: AppTypography.body.copyWith(color: colors.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: strings.tagsHint,
                                  hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                                  prefixIcon: Icon(Icons.label_outline, size: 18, color: colors.textSecondary),
                                  filled: true,
                                  fillColor: colors.appBackground,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Abstract Field
                    _buildFieldLabel(strings.abstractLabel, colors: colors),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _abstractController,
                      maxLines: 3,
                      style: AppTypography.body.copyWith(color: colors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: strings.abstractHint,
                        hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: colors.appBackground,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dialog Footer Actions
            Divider(height: 1, color: colors.divider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(strings.cancel, style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isExtracting ? null : _handleSave,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      strings.addPaperButton,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadDropzone(AppColorsExtension colors, AppStrings strings) {
    if (_selectedFile == null) {
      return InkWell(
        onTap: _pickPdfFile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_outlined, size: 30, color: colors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                strings.uploadPdfTitle,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.uploadPdfSubtitle,
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                strings.supportedFormat,
                style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _pickPdfFile,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(strings.browseFiles),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Selected File Card with Extraction Status
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _extractionComplete ? Colors.green.withValues(alpha: 0.4) : colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.name,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFileSize(_fileSizeBytes),
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _pickPdfFile,
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Đổi file', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isExtracting) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: colors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.extractingWithAi,
                    style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ] else if (_extractionComplete) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.extractionComplete,
                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false, required AppColorsExtension colors}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
