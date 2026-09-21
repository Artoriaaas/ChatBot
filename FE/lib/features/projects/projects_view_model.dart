import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/models/project.dart';
import 'package:paper_chat/services/mock_ai_service.dart';
import 'package:paper_chat/services/mock_paper_repository.dart';
import 'package:paper_chat/services/project_repository.dart';

class ProjectsViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepo;
  final MockPaperRepository _paperRepo;
  final AiService _aiService;

  Project? _activeProject;
  final Map<String, List<ChatMessage>> _projectConversations = {};
  bool _isStreaming = false;
  StreamSubscription<AiStreamEvent>? _streamSub;

  ProjectsViewModel(this._projectRepo, this._paperRepo, this._aiService);

  List<Project> get projects => _projectRepo.getAllProjects();
  Project? get activeProject => _activeProject;
  List<ChatMessage> get currentProjectMessages =>
      _activeProject != null ? (_projectConversations[_activeProject!.id] ?? []) : [];
  bool get isStreaming => _isStreaming;

  void setActiveProject(Project? project) {
    if (_activeProject?.id != project?.id) {
      stopStreaming();
    }
    _activeProject = project;
    notifyListeners();
  }

  List<Paper> getPapersForProject(Project project) {
    return project.paperIds
        .map((id) => _paperRepo.getPaperById(id))
        .whereType<Paper>()
        .toList();
  }

  Future<void> createProject({
    required String title,
    required String description,
    required List<String> initialPaperIds,
  }) async {
    final project = Project(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      paperIds: initialPaperIds,
      createdAt: DateTime.now(),
    );
    await _projectRepo.addProject(project);
    _activeProject = project;
    notifyListeners();
  }

  Future<void> addPaperToActiveProject(String paperId) async {
    if (_activeProject == null) return;
    await _projectRepo.addPaperToProject(_activeProject!.id, paperId);
    _activeProject = _projectRepo.getProjectById(_activeProject!.id);
    notifyListeners();
  }

  Future<void> removePaperFromActiveProject(String paperId) async {
    if (_activeProject == null) return;
    await _projectRepo.removePaperFromProject(_activeProject!.id, paperId);
    _activeProject = _projectRepo.getProjectById(_activeProject!.id);
    notifyListeners();
  }

  Future<void> updateProjectDetails(String id, String newTitle, List<String> newPaperIds) async {
    final existing = _projectRepo.getProjectById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        title: newTitle,
        paperIds: newPaperIds,
      );
      await _projectRepo.updateProject(updated);
      if (_activeProject?.id == id) {
        _activeProject = updated;
      }
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    await _projectRepo.deleteProject(id);
    if (_activeProject?.id == id) {
      _activeProject = null;
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_activeProject == null || text.trim().isEmpty) return;
    final projectId = _activeProject!.id;
    final attachedPapers = getPapersForProject(_activeProject!);

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      citations: [],
      timestamp: DateTime.now(),
    );

    _projectConversations.putIfAbsent(projectId, () => []);
    _projectConversations[projectId]!.add(userMsg);

    final assistantMsg = ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: '',
      citations: [],
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _projectConversations[projectId]!.add(assistantMsg);
    _isStreaming = true;
    notifyListeners();

    // Use primary paper ID or fallback if project has papers
    final primaryPaperId = attachedPapers.isNotEmpty ? attachedPapers.first.id : 'attention';
    final pages = attachedPapers.isNotEmpty
        ? attachedPapers.expand((p) => p.pages).toList()
        : <PaperPage>[];

    final stream = _aiService.askQuestion(
      paperId: primaryPaperId,
      question: text,
      pages: pages,
    );

    _streamSub = stream.listen(
      (event) {
        if (_activeProject?.id != projectId) return;
        final msgs = _projectConversations[projectId]!;
        final idx = msgs.indexWhere((m) => m.id == assistantMsg.id);
        if (idx < 0) return;

        if (event.isDone) {
          // Generate cross-paper citations if multiple papers attached
          final citations = attachedPapers.isNotEmpty
              ? attachedPapers.take(2).map((p) => Citation(
                    paperId: p.id,
                    page: 1,
                    excerpt: 'Dữ liệu tổng hợp từ ${p.title}',
                    label: '[${p.id}]',
                  )).toList()
              : (event.citations ?? []);

          msgs[idx] = msgs[idx].copyWith(
            isStreaming: false,
            citations: citations,
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
        final msgs = _projectConversations[projectId]!;
        final idx = msgs.indexWhere((m) => m.id == assistantMsg.id);
        if (idx >= 0) {
          msgs[idx] = msgs[idx].copyWith(
            content: 'Có lỗi xảy ra khi xử lý phản hồi.',
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
          final msgs = _projectConversations[projectId]!;
          final idx = msgs.indexWhere((m) => m.id == assistantMsg.id);
          if (idx >= 0 && msgs[idx].isStreaming) {
            msgs[idx] = msgs[idx].copyWith(isStreaming: false);
          }
          notifyListeners();
        }
      },
    );
  }

  void stopStreaming() {
    _streamSub?.cancel();
    _streamSub = null;
    _isStreaming = false;
    notifyListeners();
  }
}

