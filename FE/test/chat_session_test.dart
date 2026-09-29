import 'package:flutter_test/flutter_test.dart';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/models/chat_session.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/features/chat/chat_view_model.dart';
import 'package:paper_chat/services/mock_ai_service.dart';

void main() {
  group('ChatSession Model Tests', () {
    test('ChatSessionSummary parses from JSON correctly', () {
      final json = {
        'id': 'session-123',
        'title': 'Tìm hiểu về Transformer',
        'documentId': 5,
        'userId': 'user-1',
        'createdAt': '2026-09-29T10:00:00Z',
        'updatedAt': '2026-09-29T10:30:00Z',
        'messageCount': 4,
        'lastQuestion': 'Cơ chế self-attention hoạt động thế nào?'
      };

      final session = ChatSessionSummary.fromJson(json);

      expect(session.id, 'session-123');
      expect(session.title, 'Tìm hiểu về Transformer');
      expect(session.documentId, 5);
      expect(session.messageCount, 4);
      expect(session.lastQuestion, 'Cơ chế self-attention hoạt động thế nào?');
    });

    test('ChatSessionDetails parses messages into user and assistant ChatMessages', () {
      final json = {
        'id': 'session-456',
        'title': 'Kiến trúc ResNet',
        'documentId': 8,
        'createdAt': '2026-09-29T11:00:00Z',
        'updatedAt': '2026-09-29T11:15:00Z',
        'messages': [
          {
            'id': 1,
            'question': 'Residual connection là gì?',
            'answer': 'Residual connection giúp giải quyết vấn đề vanishing gradient.',
            'createdAt': '2026-09-29T11:05:00Z',
            'retrievedChunks': [
              {
                'sourceIndex': 1,
                'content': 'Shortcut connection skips layers.',
                'fileName': 'resnet.pdf',
                'chunkOrder': 2
              }
            ]
          }
        ]
      };

      final details = ChatSessionDetails.fromJson(json, paperId: '8');

      expect(details.id, 'session-456');
      expect(details.title, 'Kiến trúc ResNet');
      // 1 turn of Q&A converts to 2 messages: user + assistant
      expect(details.messages.length, 2);
      expect(details.messages[0].role, MessageRole.user);
      expect(details.messages[0].content, 'Residual connection là gì?');
      expect(details.messages[1].role, MessageRole.assistant);
      expect(details.messages[1].content, 'Residual connection giúp giải quyết vấn đề vanishing gradient.');
      expect(details.messages[1].citations.length, 1);
      expect(details.messages[1].citations[0].sourceIndex, 1);
      expect(details.messages[1].citations[0].fileName, 'resnet.pdf');
    });
  });

  group('ChatViewModel Session Management Tests', () {
    test('startNewSession resets current session and active messages', () {
      final mockAi = MockAiService();
      final vm = ChatViewModel(mockAi);

      final dummyPaper = Paper(
        id: 'paper-1',
        title: 'Attention is All You Need',
        authors: ['Vaswani et al.'],
        year: 2017,
        abstractText: 'Transformer architecture',
        tags: const [],
        collection: 'AI',
        pages: const [],
      );

      vm.setCurrentPaper(dummyPaper);
      expect(vm.currentSessionId, null);
      expect(vm.currentMessages, isEmpty);

      // Start new session
      vm.startNewSession();
      expect(vm.currentSessionId, null);
      expect(vm.currentSessionTitle, null);
      expect(vm.currentMessages, isEmpty);
    });
  });
}
