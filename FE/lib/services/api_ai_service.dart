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
    String? sessionId,
  }) {
    final controller = StreamController<AiStreamEvent>();

    _processQuestion(
      controller: controller,
      paperId: paperId,
      question: question,
      selectedText: selectedText,
      pages: pages,
      sessionId: sessionId,
    );

    return controller.stream;
  }

  Future<void> _processQuestion({
    required StreamController<AiStreamEvent> controller,
    required String paperId,
    required String question,
    String? selectedText,
    required List<PaperPage> pages,
    String? sessionId,
  }) async {
    final intDocId = int.tryParse(paperId);

    try {
      final fullQuestion = selectedText != null && selectedText.isNotEmpty
          ? 'Liên quan đến trích đoạn: "$selectedText"\nCâu hỏi: $question'
          : question;

      final result = await _apiService.askQuestion(
        question: fullQuestion,
        documentId: intDocId,
        sessionId: sessionId,
      );

      final answerText = (result['answer'] as String?) ?? 'Không có câu trả lời.';
      final returnedSessionId = result['sessionId']?.toString() ?? sessionId;
      final rawSources = (result['sources'] as List<dynamic>?)?.cast<String>() ?? [];
      final rawChunks = (result['retrievedChunks'] as List<dynamic>?) ?? [];
      
      final citations = <Citation>[];
      if (rawChunks.isNotEmpty) {
        for (int i = 0; i < rawChunks.length; i++) {
          final c = rawChunks[i] is Map<String, dynamic>
              ? rawChunks[i] as Map<String, dynamic>
              : Map<String, dynamic>.from(rawChunks[i] as Map);
          final sourceIdx = (c['sourceIndex'] as int?) ?? (i + 1);
          final content = (c['content'] as String?) ?? '';
          final fileName = c['fileName'] as String?;
          final chunkOrder = c['chunkOrder'] as int?;

          final page = _findPageForExcerpt(content, pages);
          citations.add(Citation(
            paperId: paperId,
            page: page,
            excerpt: content,
            label: '[$sourceIdx]',
            sourceIndex: sourceIdx,
            fileName: fileName,
            chunkOrder: chunkOrder,
          ));
        }
      } else {
        citations.addAll(rawSources.map((src) {
          return Citation(
            paperId: paperId,
            page: 0,
            excerpt: src,
            label: '[$src]',
            fileName: src,
          );
        }));
      }

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
          sessionId: returnedSessionId,
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
        sessionId: sessionId,
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

  int _findPageForExcerpt(String excerpt, List<PaperPage> pages) {
    if (pages.isEmpty || excerpt.trim().isEmpty) return 0;

    final cleanExcerpt = excerpt.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    
    // Thử tìm đoạn 50-80 ký tự đầu tiên
    final testSnippet = cleanExcerpt.length > 60 
        ? cleanExcerpt.substring(0, 60) 
        : cleanExcerpt;

    for (int i = 0; i < pages.length; i++) {
      final pageContent = pages[i].content.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
      if (pageContent.contains(testSnippet)) {
        return i;
      }
    }

    // Thử tìm đoạn giữa
    if (cleanExcerpt.length > 90) {
      final midSnippet = cleanExcerpt.substring(30, 90);
      for (int i = 0; i < pages.length; i++) {
        final pageContent = pages[i].content.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
        if (pageContent.contains(midSnippet)) {
          return i;
        }
      }
    }

    // Fallback: đếm số từ khớp nhiều nhất
    final words = cleanExcerpt.split(' ').where((w) => w.length > 4).take(10).toList();
    if (words.isNotEmpty) {
      int bestPage = 0;
      int maxMatches = 0;
      for (int i = 0; i < pages.length; i++) {
        final pageContent = pages[i].content.toLowerCase();
        int matches = 0;
        for (final w in words) {
          if (pageContent.contains(w)) matches++;
        }
        if (matches > maxMatches) {
          maxMatches = matches;
          bestPage = i;
        }
      }
      if (maxMatches >= 2) {
        return bestPage;
      }
    }

    return 0;
  }
}
