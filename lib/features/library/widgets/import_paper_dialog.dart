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

class _PresetPaper {
  final String title;
  final List<String> authors;
  final int year;
  final String collection;
  final List<String> tags;
  final String abstractText;
  final String sectionTitle;
  final String content;

  const _PresetPaper({
    required this.title,
    required this.authors,
    required this.year,
    required this.collection,
    required this.tags,
    required this.abstractText,
    required this.sectionTitle,
    required this.content,
  });
}

class _ImportPaperDialogState extends State<ImportPaperDialog> {
  int _activeTab = 0; // 0 = Upload PDF, 1 = Presets & Manual
  
  // Upload State
  PlatformFile? _selectedFile;
  bool _isExtracting = false;
  bool _extractionComplete = false;

  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _collectionController = TextEditingController(text: 'Deep Learning');
  final _tagsController = TextEditingController(text: 'AI, LLM');
  final _abstractController = TextEditingController();
  final _contentController = TextEditingController();

  String? _titleError;

  static const List<_PresetPaper> _presets = [
    _PresetPaper(
      title: 'BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding',
      authors: ['Jacob Devlin', 'Ming-Wei Chang', 'Kenton Lee', 'Kristina Toutanova'],
      year: 2018,
      collection: 'NLP',
      tags: ['NLP', 'BERT', 'Transformer'],
      abstractText:
          'We introduce a new language representation model called BERT, which stands for Bidirectional Encoder Representations from Transformers. Unlike recent language representation models, BERT is designed to pre-train deep bidirectional representations from unlabeled text by jointly conditioning on both left and right context in all layers.',
      sectionTitle: 'Introduction and Masked LM',
      content:
          'Language model pre-training has been shown to be effective for improving many natural language processing tasks. These include sentence-level tasks such as natural language inference and paraphrasing, which predict the relationships between sentences by analyzing them holistically, as well as token-level tasks such as named entity recognition and question answering.\n\nThere are two existing strategies for applying pre-trained language representations to downstream tasks: feature-based and fine-tuning. The feature-based approach, such as ELMo, uses task-specific architectures that include the pre-trained representations as additional features. The fine-tuning approach, such as the Generative Pre-trained Transformer (OpenAI GPT), introduces minimal task-specific parameters, and is trained on the downstream tasks by simply fine-tuning all pretrained parameters.',
    ),
    _PresetPaper(
      title: 'Language Models are Few-Shot Learners (GPT-3)',
      authors: ['Tom B. Brown', 'Benjamin Mann', 'Nick Ryder', 'Melanie Subbiah', 'Dario Amodei'],
      year: 2020,
      collection: 'Deep Learning',
      tags: ['LLM', 'GPT-3', 'Few-Shot'],
      abstractText:
          'Recent work has demonstrated substantial gains on many NLP tasks and benchmarks by pre-training on a large corpus of text followed by fine-tuning on a specific task. While typically task-agnostic in architecture, this method still requires task-specific fine-tuning datasets of thousands or tens of thousands of examples. Here we show that scaling up language models greatly improves task-agnostic, few-shot performance.',
      sectionTitle: 'Few-Shot Learning Paradigms',
      content:
          'Here we examine the capacity of language models to learn tasks via few-shot demonstration without any weight updates. We train GPT-3, an autoregressive language model with 175 billion parameters, 10x more than any previous non-sparse language model, and test its performance in the few-shot setting. For all tasks, GPT-3 is applied without any gradient updates or fine-tuning, with tasks and few-shot demonstrations specified purely via text interaction with the model.',
    ),
    _PresetPaper(
      title: 'LoRA: Low-Rank Adaptation of Large Language Models',
      authors: ['Edward J. Hu', 'Yelong Shen', 'Phillip Wallis', 'Zeyuan Allen-Zhu'],
      year: 2021,
      collection: 'Deep Learning',
      tags: ['Fine-tuning', 'LoRA', 'Efficiency'],
      abstractText:
          'An important paradigm of natural language processing consists of large-scale pre-training on general domain data and adaptation to specific tasks or domains. As we pre-train larger models, full fine-tuning, which retrains all model parameters, becomes less feasible. We propose Low-Rank Adaptation, or LoRA, which freezes the pre-trained model weights and injects trainable rank decomposition matrices into each layer of the Transformer architecture.',
      sectionTitle: 'Low-Rank Parameterization',
      content:
          'LoRA allows us to train some dense layers in a neural network indirectly by optimizing rank decomposition matrices of the dense layers’ change during adaptation instead, while keeping the pre-trained weights frozen. Using GPT-3 175B as an example, we show that a very low intrinsic rank (such as r=1 or 2) suffices even when the full parameter dimension is up to 12,288, making LoRA both storage- and memory-efficient.',
    ),
    _PresetPaper(
      title: 'Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks (RAG)',
      authors: ['Patrick Lewis', 'Ethan Perez', 'Aleksandra Piktus', 'Fabio Petroni'],
      year: 2020,
      collection: 'NLP',
      tags: ['RAG', 'Search', 'Generative AI'],
      abstractText:
          'Large pre-trained language models have been shown to store factual knowledge in their parameters, and achieve state-of-the-art results when fine-tuned on downstream NLP tasks. However, their ability to precisely access and manipulate knowledge is still limited, and they often hallucinate. We build Retrieval-Augmented Generation (RAG) models where the parametric memory is a pre-trained seq2seq model and the non-parametric memory is a dense vector index of Wikipedia.',
      sectionTitle: 'RAG Architecture & Retrieval',
      content:
          'We explore a general-purpose fine-tuning recipe for Retrieval-Augmented Generation (RAG) — models which combine pre-trained parametric and non-parametric memory for language generation. We introduce RAG models where the parametric memory is a pre-trained seq2seq transformer, and the non-parametric memory is a dense vector index of Wikipedia, accessed with a neural retriever.',
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _yearController.dispose();
    _collectionController.dispose();
    _tagsController.dispose();
    _abstractController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  int _fileSizeBytes = 0;

  Future<void> _pickPdfFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file != null) {
        final bytes = file.lengthSync() ?? (await file.length()) ?? 0;
        setState(() {
          _selectedFile = file;
          _fileSizeBytes = bytes;
          _isExtracting = true;
          _extractionComplete = false;
        });

        // Simulate backend AI PDF extraction pipeline
        await Future.delayed(const Duration(milliseconds: 1000));

        // Format cleaned title from filename
        final rawName = file.name.replaceAll('.pdf', '').replaceAll('_', ' ').replaceAll('-', ' ');
        final cleanedTitle = rawName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w.length > 1 ? w[0].toUpperCase() + w.substring(1) : w)
            .join(' ');

        setState(() {
          _isExtracting = false;
          _extractionComplete = true;
          _titleController.text = cleanedTitle;
          _authorsController.text = 'Extracted Researcher, AI Collaborator';
          _yearController.text = DateTime.now().year.toString();
          _collectionController.text = 'Uploaded Papers';
          _tagsController.text = 'PDF, AI Parsed';
          _abstractController.text =
              'This paper was uploaded as "${file.name}" and automatically extracted via the AI PDF parser. '
              'The document structure has been analyzed and prepared for deep neural conversation, cross-referencing, and intelligent summarization.';
          _contentController.text =
              'Full extracted text from ${file.name}.\n\n'
              'Section 1: Overview and Scientific Background.\n'
              'Section 2: Key Methodology and Algorithmic Innovations.\n'
              'Section 3: Empirical Evaluation and Experimental Setup.\n'
              'Section 4: Conclusion, Future Research Directions & Citations.';
          _titleError = null;
        });
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi mở file: $e')),
        );
      }
    }
  }

  void _applyPreset(_PresetPaper preset) {
    setState(() {
      _titleController.text = preset.title;
      _authorsController.text = preset.authors.join(', ');
      _yearController.text = preset.year.toString();
      _collectionController.text = preset.collection;
      _tagsController.text = preset.tags.join(', ');
      _abstractController.text = preset.abstractText;
      _contentController.text = preset.content;
      _titleError = null;
    });
  }

  String _formatFileSize(int bytes) {
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

    final abstractText = _abstractController.text.trim().isNotEmpty
        ? _abstractController.text.trim()
        : 'No abstract provided.';

    final content = _contentController.text.trim().isNotEmpty
        ? _contentController.text.trim()
        : abstractText;

    final newPaper = Paper(
      id: 'paper_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      authors: authorsList.isNotEmpty ? authorsList : ['Author Unknown'],
      year: year,
      abstractText: abstractText,
      collection: collection,
      tags: tagsList.isNotEmpty ? tagsList : ['Research'],
      pages: [
        PaperPage(
          pageNumber: 1,
          sectionTitle: 'Abstract & Overview',
          content: '$abstractText\n\n$content',
        ),
        PaperPage(
          pageNumber: 2,
          sectionTitle: 'Methodology & Key Findings',
          content: content,
        ),
        PaperPage(
          pageNumber: 3,
          sectionTitle: 'Discussion & Conclusion',
          content: 'Analysis, experimental observations and future directions for $title.\n\n$content',
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
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 740),
        child: Column(
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.cloud_upload_rounded, color: colors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.addNewPaperTitle,
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.addNewPaperSubtitle,
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

            // Tab bar: [Tải file PDF lên | Mẫu có sẵn & Tùy chỉnh]
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: colors.appBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: strings.uploadTab,
                      icon: Icons.picture_as_pdf_rounded,
                      isSelected: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: strings.manualTab,
                      icon: Icons.auto_awesome_rounded,
                      isSelected: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Divider(height: 1, color: colors.divider),

            // Dialog Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_activeTab == 0) ...[
                      // Upload PDF Mode
                      _buildUploadDropzone(colors, strings),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Quick Presets Bar
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            strings.quickPresets,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presets.map((preset) {
                          return ActionChip(
                            avatar: Icon(Icons.description_outlined, size: 14, color: colors.primary),
                            label: Text(
                              preset.title.length > 32 ? '${preset.title.substring(0, 32)}...' : preset.title,
                              style: TextStyle(fontSize: 11, color: colors.textPrimary),
                            ),
                            backgroundColor: colors.surfaceElevated,
                            side: BorderSide(color: colors.divider),
                            onPressed: () => _applyPreset(preset),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section Title: Thông tin nghiên cứu đã trích xuất / nhập
                    Text(
                      _activeTab == 0 ? 'Thông tin bài báo (Được trích xuất từ file)' : 'Thông tin bài báo',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Paper Title
                    _buildFieldLabel(strings.paperTitleLabel, isRequired: true, colors: colors),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: AppTypography.body.copyWith(color: colors.textPrimary),
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
                        if (_titleError != null) setState(() => _titleError = null);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Authors & Year (Row)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(strings.authorsLabel, colors: colors),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _authorsController,
                                style: AppTypography.body.copyWith(color: colors.textPrimary),
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
                                style: AppTypography.body.copyWith(color: colors.textPrimary),
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

                    // Collection & Tags (Row)
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
                                style: AppTypography.body.copyWith(color: colors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Deep Learning',
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
                                style: AppTypography.body.copyWith(color: colors.textPrimary),
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

                    // Abstract
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
                    const SizedBox(height: 14),

                    // Detailed Content
                    _buildFieldLabel(strings.paperContentLabel, colors: colors),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _contentController,
                      maxLines: 3,
                      style: AppTypography.body.copyWith(color: colors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: strings.paperContentHint,
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
                    label: Text(strings.addPaperButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
                width: 56,
                height: 56,
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
              ),
              const SizedBox(height: 8),
              Text(
                strings.supportedFormat,
                style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
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
                  width: 12,
                  height: 12,
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

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? colors.primary : colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
