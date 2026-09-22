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
        final authors = rawAuthors
            .split(',')
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList();
        final year = item['year'] as int? ?? DateTime.now().year;
        final abstractText =
            item['abstractText'] as String? ?? 'Chưa có tóm tắt.';
        final collection = item['collection'] as String? ?? 'Tài liệu Backend';
        final rawTags = item['tags'] as String? ?? 'Research';
        final tags = rawTags
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        final isFavorite = item['isFavorite'] as bool? ?? false;
        final indexStatus = item['indexStatus'] as String? ?? 'Completed';

        final paper = Paper(
          id: id,
          documentId: item['documentId']?.toString(),
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
              content:
                  '$abstractText\n\nNội dung bài báo "$title" đã được hệ thống Backend lưu trữ và tạo vector chỉ mục AI (Trạng thái: $indexStatus).',
            ),
          ],
        );

        _remotePapers.add(paper);
      }
    } catch (_) {
      _remotePapers.clear();
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

      final paperId =
          result['paperId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      await fetchRemotePapers();
      return getPaperById(paperId) ??
          Paper(
            id: paperId,
            title: title ?? fileName,
            authors: authors != null
                ? authors.split(',').map((a) => a.trim()).toList()
                : ['Tài liệu tải lên'],
            year: year ?? DateTime.now().year,
            abstractText: abstractText ?? 'Đang xử lý...',
            tags: tags != null
                ? tags.split(',').map((t) => t.trim()).toList()
                : ['Backend'],
            collection: collection ?? 'Tài liệu Backend',
            pages: const [],
          );
    } catch (e) {
      rethrow;
    }
  }

  @override
  List<Paper> getAllPapers() {
    return List.unmodifiable(_remotePapers);
  }

  @override
  Paper? getPaperById(String id) {
    try {
      return _remotePapers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void addPaper(Paper paper) {
    _remotePapers.insert(0, paper);
  }
}
