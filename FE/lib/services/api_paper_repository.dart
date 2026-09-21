import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/api_service.dart';
import 'package:paper_chat/services/mock_paper_repository.dart';

class ApiPaperRepository extends MockPaperRepository {
  final ApiService _apiService;
  final List<Paper> _remotePapers = [];

  ApiPaperRepository(this._apiService);

  /// Lấy danh sách tài liệu từ Backend và cập nhật danh sách local
  Future<List<Paper>> fetchRemotePapers() async {
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
    } catch (e) {
      print('[ApiPaperRepository] Không thể tải danh sách tài liệu từ Backend: $e');
    }
    return getAllPapers();
  }

  /// Tải file tài liệu lên Backend và thêm vào danh sách hiển thị
  Future<Paper> uploadAndAddPaper(List<int> bytes, String fileName) async {
    final result = await _apiService.uploadDocument(bytes, fileName);
    final docId = result['documentId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    final paper = Paper(
      id: docId,
      title: fileName,
      authors: ['Tài liệu tải lên'],
      year: DateTime.now().year,
      abstractText: 'Tài liệu vừa tải lên Backend thành công, đang tiến hành lập chỉ mục AI trong nền...',
      tags: ['Backend', 'Pending'],
      collection: 'Tài liệu Backend',
      pages: [
        PaperPage(
          pageNumber: 1,
          sectionTitle: 'Đang xử lý',
          content: 'Nội dung file $fileName đang được hệ thống Backend trích xuất text và tạo embedding vector...',
        ),
      ],
    );

    _remotePapers.insert(0, paper);
    return paper;
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
