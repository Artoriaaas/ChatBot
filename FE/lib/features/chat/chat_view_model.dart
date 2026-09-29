import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/models/chat_session.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/api_service.dart';
import 'package:paper_chat/services/mock_ai_service.dart';

class ChatViewModel extends ChangeNotifier {
  final AiService _aiService;
  final ApiService? _apiService;

  final Map<String, List<ChatMessage>> _conversations = {};
  List<Map<String, dynamic>> _chatHistory = [];
  List<ChatSessionSummary> _chatSessions = [];
  String? _currentSessionId;
  String? _currentSessionTitle;
  String? _currentPaperId;
  Paper? _currentPaper;
  bool _isStreaming = false;
  bool _isHistoryLoading = false;
  String? _historyError;
  int _historyRequestVersion = 0;
  StreamSubscription<AiStreamEvent>? _streamSub;
  String? _selectedTextForChat;
  String? _scope;

  ChatViewModel(this._aiService, [this._apiService]);

  Paper? get currentPaper => _currentPaper;
  String? get currentSessionId => _currentSessionId;
  String? get currentSessionTitle => _currentSessionTitle;
  List<ChatMessage> get currentMessages =>
      _conversations[_currentPaperId] ?? [];
  List<Map<String, dynamic>> get chatHistory => _chatHistory;
  List<ChatSessionSummary> get chatSessions => _chatSessions;
  bool get isStreaming => _isStreaming;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;
  String? get selectedTextForChat => _selectedTextForChat;
  String get scope => _scope ?? 'paper';

  void setCurrentPaper(Paper paper) {
    final changedPaper = _currentPaperId != paper.id;
    if (changedPaper) {
      stopStreaming();
      _chatHistory = [];
      _chatSessions = [];
      _currentSessionId = null;
      _currentSessionTitle = null;
      _historyError = null;
      _isHistoryLoading = false;
    }
    _currentPaperId = paper.id;
    _currentPaper = paper;
    notifyListeners();
    if (changedPaper) {
      unawaited(loadChatSessions());
    }
  }

  void startNewSession() {
    stopStreaming();
    _currentSessionId = null;
    _currentSessionTitle = null;
    if (_currentPaperId != null) {
      _conversations[_currentPaperId!] = [];
    }
    notifyListeners();
  }

  Future<void> loadChatSessions() async {
    final requestVersion = ++_historyRequestVersion;
    final documentId = int.tryParse(_currentPaper?.documentId ?? '');
    if (_apiService == null || documentId == null) {
      _chatSessions = [];
      _chatHistory = [];
      _isHistoryLoading = false;
      _historyError = null;
      notifyListeners();
      return;
    }

    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();

    try {
      final sessionsRaw = await _apiService.getChatSessions(
        documentId: documentId,
        take: 50,
      );
      if (requestVersion != _historyRequestVersion) return;

      _chatSessions = sessionsRaw
          .map((s) => ChatSessionSummary.fromJson(s))
          .toList();

      // Đồng thời nạp lịch sử legacy để fallback nếu chưa có session nào
      final legacyHistory = await _apiService.getHistory(
        documentId: documentId,
        take: 50,
      );
      if (requestVersion != _historyRequestVersion) return;
      _chatHistory = legacyHistory;
    } catch (error) {
      if (requestVersion != _historyRequestVersion) return;
      _historyError = error.toString();
    } finally {
      if (requestVersion == _historyRequestVersion) {
        _isHistoryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectSession(String sessionId) async {
    if (_apiService == null || _currentPaperId == null) return;

    try {
      final rawDetails = await _apiService.getChatSessionDetails(sessionId);
      final details = ChatSessionDetails.fromJson(
        rawDetails,
        paperId: _currentPaper?.documentId ?? _currentPaperId,
        pages: _currentPaper?.pages ?? [],
      );

      _currentSessionId = details.id;
      _currentSessionTitle = details.title;
      _conversations[_currentPaperId!] = details.messages;
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatViewModel] Lỗi tải chi tiết phiên chat: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    if (_apiService == null) return;

    try {
      await _apiService.deleteChatSession(sessionId);
      _chatSessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        startNewSession();
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatViewModel] Lỗi xóa phiên chat: $e');
    }
  }

  Future<void> loadChatHistory() async {
    await loadChatSessions();
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

    final activeSession = _currentSessionId;

    final stream = _aiService.askQuestion(
      paperId: _currentPaper?.documentId ?? paperId,
      question: text,
      selectedText: _selectedTextForChat,
      pages: _currentPaper!.pages,
      sessionId: activeSession,
    );

    _streamSub = stream.listen(
      (event) {
        if (_currentPaperId != paperId) return;
        final msgs = _conversations[paperId]!;
        final idx = msgs.indexWhere((m) => m.id == assistantMsg.id);
        if (idx < 0) return;

        if (event.sessionId != null && event.sessionId!.isNotEmpty) {
          _currentSessionId = event.sessionId;
          if (_currentSessionTitle == null ||
              _currentSessionTitle == 'Cuộc trò chuyện mới') {
            _currentSessionTitle = text.length > 50
                ? '${text.substring(0, 47)}...'
                : text;
          }
        }

        if (event.isDone) {
          msgs[idx] = msgs[idx].copyWith(
            isStreaming: false,
            citations: event.citations ?? [],
          );
          _isStreaming = false;
          unawaited(loadChatSessions());
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
