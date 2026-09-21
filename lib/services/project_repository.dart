import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paper_chat/models/project.dart';

class ProjectRepository {
  static const _key = 'paper_ink_projects';
  late SharedPreferences _prefs;
  List<Project> _projects = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProjects();
  }

  void _loadProjects() {
    final jsonStr = _prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        _projects = list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _initDefaults();
      }
    } else {
      _initDefaults();
    }
  }

  void _initDefaults() {
    _projects = [
      Project(
        id: 'proj_1',
        title: 'Transformer Architecture & RAG',
        description: 'So sánh các mô hình Transformer và kỹ thuật Retrieval-Augmented Generation',
        paperIds: ['1', '2'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Project(
        id: 'proj_2',
        title: 'Deep Learning Review',
        description: 'Tải và tổng hợp tài liệu về mạng nơ-ron sâu',
        paperIds: ['3'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
    _saveProjects();
  }

  Future<void> _saveProjects() async {
    final jsonStr = jsonEncode(_projects.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, jsonStr);
  }

  List<Project> getAllProjects() => List.unmodifiable(_projects);

  Project? getProjectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProject(Project project) async {
    _projects.insert(0, project);
    await _saveProjects();
  }

  Future<void> updateProject(Project project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      _projects[idx] = project;
      await _saveProjects();
    }
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _saveProjects();
  }

  Future<void> addPaperToProject(String projectId, String paperId) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx >= 0) {
      final current = _projects[idx];
      if (!current.paperIds.contains(paperId)) {
        final updated = current.copyWith(
          paperIds: [...current.paperIds, paperId],
        );
        _projects[idx] = updated;
        await _saveProjects();
      }
    }
  }

  Future<void> removePaperFromProject(String projectId, String paperId) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx >= 0) {
      final current = _projects[idx];
      final updatedPaperIds = List<String>.from(current.paperIds)..remove(paperId);
      final updated = current.copyWith(paperIds: updatedPaperIds);
      _projects[idx] = updated;
      await _saveProjects();
    }
  }
}

