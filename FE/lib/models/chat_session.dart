import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/models/paper.dart';

class ChatSessionSummary {
  final String id;
  final String title;
  final int? documentId;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastQuestion;

  ChatSessionSummary({
    required this.id,
    required this.title,
    this.documentId,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastQuestion,
  });

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return ChatSessionSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Cuộc trò chuyện mới',
      documentId: json['documentId'] is int
          ? json['documentId'] as int
          : int.tryParse(json['documentId']?.toString() ?? ''),
      userId: json['userId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      messageCount: (json['messageCount'] as int?) ?? 0,
      lastQuestion: json['lastQuestion']?.toString(),
    );
  }

  ChatSessionSummary copyWith({
    String? id,
    String? title,
    int? documentId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? lastQuestion,
  }) {
    return ChatSessionSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastQuestion: lastQuestion ?? this.lastQuestion,
    );
  }
}

class ChatSessionDetails {
  final String id;
  final String title;
  final int? documentId;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSessionDetails({
    required this.id,
    required this.title,
    this.documentId,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ChatSessionDetails.fromJson(
    Map<String, dynamic> json, {
    String? paperId,
    List<PaperPage> pages = const [],
  }) {
    final sessionId = json['id']?.toString() ?? '';
    final rawMessages = (json['messages'] as List<dynamic>?) ?? [];

    final convertedMessages = <ChatMessage>[];

    for (final m in rawMessages) {
      if (m is! Map<String, dynamic> && m is! Map) continue;
      final map = Map<String, dynamic>.from(m as Map);

      final q = map['question']?.toString() ?? '';
      final a = map['answer']?.toString() ?? '';
      final msgId = map['id']?.toString() ?? '';
      final createdAt =
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now();

      final rawChunks = (map['retrievedChunks'] as List<dynamic>?) ?? [];
      final citations = <Citation>[];

      for (int i = 0; i < rawChunks.length; i++) {
        final c = rawChunks[i] is Map
            ? Map<String, dynamic>.from(rawChunks[i] as Map)
            : <String, dynamic>{};
        final sourceIdx = (c['sourceIndex'] as int?) ?? (i + 1);
        final content = (c['content'] as String?) ?? '';
        final fileName = c['fileName'] as String?;
        final chunkOrder = c['chunkOrder'] as int?;

        citations.add(Citation(
          paperId: paperId ?? '',
          page: 0,
          excerpt: content,
          label: '[$sourceIdx]',
          sourceIndex: sourceIdx,
          fileName: fileName,
          chunkOrder: chunkOrder,
        ));
      }

      if (q.isNotEmpty) {
        convertedMessages.add(ChatMessage(
          id: 'user_${msgId}_${createdAt.millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: q,
          citations: const [],
          timestamp: createdAt,
          isStreaming: false,
          isError: false,
        ));
      }

      if (a.isNotEmpty) {
        convertedMessages.add(ChatMessage(
          id: 'ai_${msgId}_${createdAt.millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: a,
          citations: citations,
          timestamp: createdAt,
          isStreaming: false,
          isError: false,
        ));
      }
    }

    return ChatSessionDetails(
      id: sessionId,
      title: json['title']?.toString() ?? 'Cuộc trò chuyện mới',
      documentId: json['documentId'] is int
          ? json['documentId'] as int
          : int.tryParse(json['documentId']?.toString() ?? ''),
      userId: json['userId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      messages: convertedMessages,
    );
  }
}
