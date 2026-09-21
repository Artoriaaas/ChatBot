import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/api_service.dart';
import 'package:paper_chat/services/mock_paper_repository.dart';

class ApiPaperRepository extends MockPaperRepository {
  final ApiService _apiService;
  final List<Paper> _remotePapers = [];

  ApiPaperRepository(this._apiService);

  /// Lấy danh sách Paper từ Backend và cập nhật danh sách local
  Future<List<Paper>> fetchRemotePapers() async {
    try {
      // 1. Thử gọi API Paper chính thức
      final papersData = await _apiService.getPapers();
      _remotePapers.clear();

      for (final item in papersData) {
        final id = item['id']?.toString() ?? '0';
        final title = item['title'] as String? ?? 'Bài báo không tiêu đề';
        final rawAuthors = item['authors'] as String? ?? 'Tác giả chưa rõ';
        final authors = rawAuthors.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
        final year = item['year'] as int? ?? DateTime.now().year;
        final abstractText = item['abstractText'] as String? ?? 'Chưa có tóm tắt.';
        final collection = item['collection'] as String? ?? 'Tài liệu Backend';
        final rawTags = item['tags'] as String? ?? 'Research';
        final tags = rawTags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
        final isFavorite = item['isFavorite'] as bool? ?? false;
        final indexStatus = item['indexStatus'] as String? ?? 'Completed';

        final paper = Paper(
          id: id,
          title: title,
          authors: authors.isNotEmpty ? authors : ['Nghiên cứu viên'],
          year: year,
          abstractText: abstractText,
          tags: tags,
          collection: collection,
          isFavorite: isFavorite,
          pages: [
            PaperPage(
              pageNumber: 1,
              sectionTitle: 'Tóm tắt & Nội dung bài báo',
              content: '$abstractText\n\nNội dung bài báo "$title" đã được hệ thống Backend lưu trữ và tạo vector chỉ mục AI (Trạng thái: $indexStatus).',
            ),
          ],
        );

        _remotePapers.add(paper);
      }
    } catch (e) {
      // 2. Fallback sang API Documents nếu chưa có dữ liệu Paper
      try {
        final docs = await _apiService.getDocuments();
        _remotePapers.clear();

        for (final doc in docs) {
          final id = doc['id']?.toString() ?? '0';
          final fileName = doc['fileName'] as String? ?? 'Document $id';
          final fileSize = doc['fileSize'] as int? ?? 0;
          final uploadDateStr = doc['uploadDate'] as String?;
          final uploadYear = uploadDateStr != null ? (DateTime.tryParse(uploadDateStr)?.year ?? 2026) : 2026;
          final indexStatus = doc['indexStatus'] as String? ?? 'Unknown';

          final paper = Paper(
            id: id,
            title: fileName,
            authors: ['Uploaded File', '${(fileSize / 1024).toStringAsFixed(1)} KB'],
            year: uploadYear,
            abstractText: 'Tài liệu đã được tải lên Backend và lưu giữ trong PostgreSQL vector (Trạng thái AI: $indexStatus).',
            tags: ['Backend', indexStatus],
            collection: 'Tài liệu Backend',
            pages: [
              PaperPage(
                pageNumber: 1,
                sectionTitle: 'Thông tin tài liệu',
                content: 'Tên file: $fileName\nTrạng thái Lập chỉ mục: $indexStatus\nĐường dẫn: ${doc['filePath'] ?? 'N/A'}',
              ),
            ],
          );

          _remotePapers.add(paper);
        }
      } catch (_) {}
    }
    return getAllPapers();
  }

  /// Tải file tài liệu/bài báo lên Backend và thêm vào danh sách hiển thị
  Future<Paper> uploadAndAddPaper(
    List<int> bytes,
    String fileName, {
    String? title,
    String? authors,
    int? year,
    String? collection,
    String? tags,
    String? abstractText,
  }) async {
    try {
      final result = await _apiService.uploadPaper(
        bytes,
        fileName,
        title: title,
        authors: authors,
        year: year,
        collection: collection,
        tags: tags,
        abstractText: abstractText,
      );

      final paperId = result['paperId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

      final paper = Paper(
        id: paperId,
        title: title ?? fileName,
        authors: authors != null ? authors.split(',').map((a) => a.trim()).toList() : ['Tài liệu tải lên'],
        year: year ?? DateTime.now().year,
        abstractText: abstractText ?? 'Tài liệu vừa tải lên Backend thành công, đang tiến hành lập chỉ mục AI trong nền...',
        tags: tags != null ? tags.split(',').map((t) => t.trim()).toList() : ['Backend', 'Pending'],
        collection: collection ?? 'Tài liệu Backend',
        pages: [
          PaperPage(
            pageNumber: 1,
            sectionTitle: 'Đang xử lý',
            content: 'Nội dung tệp $fileName đang được hệ thống Backend trích xuất văn bản và tạo vector embedding...',
          ),
        ],
      );

      _remotePapers.insert(0, paper);
      return paper;
    } catch (e) {
      // Fallback sang uploadDocument nếu uploadPaper lỗi
      final result = await _apiService.uploadDocument(bytes, fileName);
      final docId = result['documentId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

      final paper = Paper(
        id: docId,
        title: fileName,
        authors: ['Tài liệu tải lên'],
        year: DateTime.now().year,
        abstractText: 'Tài liệu vừa tải lên Backend thành công.',
        tags: ['Backend', 'Pending'],
        collection: 'Tài liệu Backend',
        pages: [
          PaperPage(
            pageNumber: 1,
            sectionTitle: 'Đang xử lý',
            content: 'Nội dung tệp $fileName đang được hệ thống Backend trích xuất text...',
          ),
        ],
      );

      _remotePapers.insert(0, paper);
      return paper;
    }
  }

  @override
  List<Paper> getAllPapers() {
    return [..._remotePapers, ...super.getAllPapers()];
  }

  @override
  Paper? getPaperById(String id) {
    try {
      return _remotePapers.firstWhere((p) => p.id == id);
    } catch (_) {
      return super.getPaperById(id);
    }
  }

  @override
  void addPaper(Paper paper) {
    _remotePapers.insert(0, paper);
  }
}
