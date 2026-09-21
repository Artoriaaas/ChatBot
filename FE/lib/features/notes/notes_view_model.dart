import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paper_chat/models/note.dart';
import 'package:paper_chat/services/notes_repository.dart';

class NotesViewModel extends ChangeNotifier {
  final NotesRepository _repo;
  String _searchQuery = '';
  
  NotesViewModel(this._repo);
  
  String get searchQuery => _searchQuery;
  set searchQuery(String v) { 
    _searchQuery = v; 
    notifyListeners(); 
  }
  
  List<Note> get filteredNotes {
    final all = _repo.getAllNotes();
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((n) =>
      n.content.toLowerCase().contains(q) ||
      n.paperTitle.toLowerCase().contains(q) ||
      n.sectionTitle.toLowerCase().contains(q)
    ).toList();
  }
  
  Future<void> addNote(Note note) async {
    await _repo.addNote(note);
    notifyListeners();
  }
  
  Future<void> updateNote(Note note) async {
    await _repo.updateNote(note);
    notifyListeners();
  }
  
  Future<void> deleteNote(String noteId) async {
    await _repo.deleteNote(noteId);
    notifyListeners();
  }
  
  Future<String?> exportAsMarkdown() async {
    try {
      final notes = _repo.getAllNotes();
      if (notes.isEmpty) return null;

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/paper_ink_notes_${DateTime.now().millisecondsSinceEpoch}.md');
      
      final buffer = StringBuffer();
      buffer.writeln('# Paper & Ink Notes\n');
      
      for (final note in notes) {
        buffer.writeln('## ${note.paperTitle}');
        buffer.writeln('**Page ${note.page} · ${note.sectionTitle}**\n');
        buffer.writeln('${note.content}\n');
        buffer.writeln('*Created at: ${note.createdAt}*\n');
        buffer.writeln('---\n');
      }
      
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      debugPrint('Export failed: $e');
      return null;
    }
  }
}
