import 'dart:async';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/api_service.dart';
import 'package:paper_chat/services/mock_ai_service.dart';

class ApiAiService implements AiService {
  final ApiService _apiService;
  final MockAiService _mockAiService;

  ApiAiService(this._apiService, [MockAiService? mockAiService])
      : _mockAiService = mockAiService ?? MockAiService();

  @override
  Stream<AiStreamEvent> askQuestion({
    required String paperId,
    required String question,
    String? selectedText,
    required List<PaperPage> pages,
  }) {
    final controller = StreamController<AiStreamEvent>();

    _processQuestion(
      controller: controller,
      paperId: paperId,
      question: question,
      selectedText: selectedText,
      pages: pages,
    );

    return controller.stream;
  }

  Future<void> _processQuestion({
    required StreamController<AiStreamEvent> controller,
    required String paperId,
    required String question,
    String? selectedText,
    required List<PaperPage> pages,
  }) async {
    final intDocId = int.tryParse(paperId);

    try {
      final fullQuestion = selectedText != null && selectedText.isNotEmpty
          ? 'Liên quan đến trích đoạn: "$selectedText"\nCâu hỏi: $question'
          : question;

      final result = await _apiService.askQuestion(
        question: fullQuestion,
        documentId: intDocId,
      );

      final answerText = (result['answer'] as String?) ?? 'Không có câu trả lời.';
      final rawSources = (result['sources'] as List<dynamic>?)?.cast<String>() ?? [];
      
      final citations = rawSources.map((src) {
        return Citation(
          paperId: paperId,
          page: 1,
          excerpt: src,
          label: '[$src]',
        );
      }).toList();

      // Giả lập hiệu ứng gõ chữ (typing effect) từ câu trả lời của BE
      final words = answerText.split(' ');
      for (int i = 0; i < words.length; i += 3) {
        if (controller.isClosed) return;

        final chunkWords = words.sublist(i, (i + 3 < words.length) ? i + 3 : words.length);
        final chunk = chunkWords.join(' ') + (i + 3 < words.length ? ' ' : '');

        final isLast = (i + 3 >= words.length);

        controller.add(AiStreamEvent(
          textChunk: chunk,
          citations: isLast ? citations : null,
          isDone: isLast,
        ));

        await Future.delayed(const Duration(milliseconds: 30));
      }

      if (!controller.isClosed) {
        controller.close();
      }
    } catch (e) {
      // Fallback sang Mock AI Service nếu BE offline hoặc gặp lỗi
      print('[ApiAiService] Gặp lỗi khi gọi Backend RAG API ($e), chuyển hướng sang Mock AI Service.');
      final mockStream = _mockAiService.askQuestion(
        paperId: paperId,
        question: question,
        selectedText: selectedText,
        pages: pages,
      );

      mockStream.listen(
        (event) {
          if (!controller.isClosed) {
            controller.add(event);
          }
        },
        onError: (err) {
          if (!controller.isClosed) {
            controller.addError(err);
          }
        },
        onDone: () {
          if (!controller.isClosed) {
            controller.close();
          }
        },
      );
    }
  }
}
