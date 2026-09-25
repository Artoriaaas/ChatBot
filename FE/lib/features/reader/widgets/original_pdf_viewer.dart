import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/api_service.dart';

class OriginalPdfViewer extends StatefulWidget {
  final Paper paper;
  final AppStrings strings;
  final VoidCallback? onDownload;

  const OriginalPdfViewer({
    super.key,
    required this.paper,
    required this.strings,
    this.onDownload,
  });

  @override
  State<OriginalPdfViewer> createState() => _OriginalPdfViewerState();
}

class _OriginalPdfViewerState extends State<OriginalPdfViewer> {
  final _apiService = ApiService();
  final _pdfController = PdfViewerController();

  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isNotPdf = false;
  int _currentPage = 1;
  int _pageCount = 1;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(covariant OriginalPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paper.id != widget.paper.id) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNotPdf = false;
    });

    try {
      final paperId = int.tryParse(widget.paper.id);
      if (paperId == null) {
        throw Exception('Mã bài báo không hợp lệ.');
      }

      final bytes = await _apiService.downloadPaperFileBytes(paperId);

      // Check if file is PDF (magic bytes %PDF = 0x25, 0x50, 0x44, 0x46)
      final isPdf = bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;

      if (!mounted) return;

      if (!isPdf) {
        setState(() {
          _pdfBytes = bytes;
          _isNotPdf = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _pdfBytes = bytes;
          _isNotPdf = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternal() async {
    final paperId = int.tryParse(widget.paper.id);
    if (paperId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final url = _apiService.getPaperFileUrl(paperId, download: false);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Không thể mở liên kết: $url')),
        );
      }
    }
  }

  Future<void> _downloadFile() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_pdfBytes == null) {
      final paperId = int.tryParse(widget.paper.id);
      if (paperId == null) return;
      final url = _apiService.getPaperFileUrl(paperId, download: true);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final sanitizedTitle = widget.paper.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final ext = _isNotPdf ? 'docx' : 'pdf';
      final savePath = '${dir.path}${io.Platform.pathSeparator}$sanitizedTitle.$ext';
      final file = io.File(savePath);
      await file.writeAsBytes(_pdfBytes!);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Đã lưu file tại: $savePath'),
            action: SnackBarAction(
              label: 'Mở',
              onPressed: () async {
                final fileUri = Uri.file(savePath);
                if (await canLaunchUrl(fileUri)) {
                  await launchUrl(fileUri);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.strings;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text(
              strings.loadingOriginalPdf,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Không thể tải file gốc',
                style: AppTypography.heading3.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadFile,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Thử lại'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(strings.openInExternalApp),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_isNotPdf) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 56, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                widget.paper.title,
                textAlign: TextAlign.center,
                style: AppTypography.heading3.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                strings.cannotPreviewNonPdf,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _downloadFile,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(strings.downloadOriginalFile),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(strings.openInExternalApp),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Floating viewer control bar
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.paper.title.isNotEmpty ? widget.paper.title : 'PDF Gốc',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Page indicator
              Text(
                '$_currentPage/$_pageCount',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 16),
                tooltip: 'Trang trước',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _currentPage > 1
                    ? () => _pdfController.goToPage(pageNumber: _currentPage - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 16),
                tooltip: 'Trang sau',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _currentPage < _pageCount
                    ? () => _pdfController.goToPage(pageNumber: _currentPage + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 16),
                tooltip: 'Thu nhỏ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _pdfController.zoomDown(),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 16),
                tooltip: 'Phóng to',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _pdfController.zoomUp(),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 16),
                tooltip: strings.downloadOriginalFile,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _downloadFile,
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 16),
                tooltip: strings.openInExternalApp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _openExternal,
              ),
            ],
          ),
        ),

        // PDF Canvas
        Expanded(
          child: PdfViewer.data(
            _pdfBytes!,
            sourceName: '${widget.paper.title}.pdf',
            controller: _pdfController,
            params: PdfViewerParams(
              backgroundColor: colors.appBackground,
              onPageChanged: (page) {
                if (mounted && page != null) {
                  setState(() => _currentPage = page);
                }
              },
              onViewerReady: (document, controller) {
                if (mounted) {
                  setState(() {
                    _pageCount = document.pages.length;
                    _currentPage = 1;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
