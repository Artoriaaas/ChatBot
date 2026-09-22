import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/mock_ai_service.dart';

class ChatViewModel extends ChangeNotifier {
  final AiService _aiService;

  final Map<String, List<ChatMessage>> _conversations = {};
  String? _currentPaperId;
  Paper? _currentPaper;
  bool _isStreaming = false;
  StreamSubscription<AiStreamEvent>? _streamSub;
  String? _selectedTextForChat;
  String? _scope;

  ChatViewModel(this._aiService);

  List<ChatMessage> get currentMessages =>
      _conversations[_currentPaperId] ?? [];
  bool get isStreaming => _isStreaming;
  String? get selectedTextForChat => _selectedTextForChat;
  String get scope => _scope ?? 'paper';

  void setCurrentPaper(Paper paper) {
    if (_currentPaperId != paper.id) {
      stopStreaming();
    }
    _currentPaperId = paper.id;
    _currentPaper = paper;
    notifyListeners();
  }

  void setSelectedText(String? text) {
    _selectedTextForChat = text;
    _scope = text != null ? 'selection' : 'paper';
    notifyListeners();
  }

  void clearSelectedText() {
    _selectedTextForChat = null;
    _scope = 'paper';
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_currentPaperId == null || _currentPaper == null) return;
    if (text.trim().isEmpty) return;

    final paperId = _currentPaperId!;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      citations: [],
      timestamp: DateTime.now(),
      selectedText: _selectedTextForChat,
      isStreaming: false,
      isError: false,
    );
    _conversations.putIfAbsent(paperId, () => []);
    _conversations[paperId]!.add(userMsg);

    final assistantMsg = ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: '',
      citations: [],
      timestamp: DateTime.now(),
      isStreaming: true,
      isError: false,
    );
    _conversations[paperId]!.add(assistantMsg);
    _isStreaming = true;
    notifyListeners();

    final stream = _aiService.askQuestion(
      paperId: _currentPaper?.documentId ?? paperId,
      question: text,
      selectedText: _selectedTextForChat,
      pages: _currentPaper!.pages,
    );

    _streamSub = stream.listen(
      (event) {
        if (_currentPaperId != paperId) return;
        final msgs = _conversations[paperId]!;
        final idx = msgs.indexWhere((m) => m.id == assistantMsg.id);
        if (idx < 0) return;

        if (event.isDone) {
          msgs[idx] = msgs[idx].copyWith(
            isStreaming: false,
            citations: event.citations ?? [],
          );
          _isStreaming = false;
        } else {
          msgs[idx] = msgs[idx].copyWith(
            content: msgs[idx].content + event.textChunk,
          );
        }
        notifyListeners();
      },
      onError: (e) {
        final msgs = _conversations[paperId]!;
        final idx = msgs.indexWhere((m) => m.id == assistantMsg.id);
        if (idx >= 0) {
          msgs[idx] = msgs[idx].copyWith(
            content: 'An error occurred. Please try again.',
            isStreaming: false,
            isError: true,
          );
        }
        _isStreaming = false;
        notifyListeners();
      },
      onDone: () {
        if (_isStreaming) {
          _isStreaming = false;
          final msgs = _conversations[paperId]!;
          final idx = msgs.indexWhere((m) => m.id == assistantMsg.id);
          if (idx >= 0 && msgs[idx].isStreaming) {
            msgs[idx] = msgs[idx].copyWith(isStreaming: false);
          }
          notifyListeners();
        }
      },
    );

    _selectedTextForChat = null;
  }

  void stopStreaming() {
    _streamSub?.cancel();
    _streamSub = null;
    _isStreaming = false;
    if (_currentPaperId != null) {
      final msgs = _conversations[_currentPaperId!];
      if (msgs != null) {
        final idx = msgs.indexWhere((m) => m.isStreaming);
        if (idx >= 0) {
          msgs[idx] = msgs[idx].copyWith(isStreaming: false);
        }
      }
    }
    notifyListeners();
  }

  void retryLast() {
    if (_currentPaperId == null) return;
    final msgs = _conversations[_currentPaperId!];
    if (msgs == null || msgs.length < 2) return;
    msgs.removeLast();
    final lastUser = msgs.last;
    if (lastUser.role == MessageRole.user) {
      msgs.removeLast();
      _selectedTextForChat = lastUser.selectedText;
      sendMessage(lastUser.content);
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
