import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paper_chat/models/note.dart';

class NotesRepository {
  static const _key = 'paper_ink_notes';
  late SharedPreferences _prefs;
  List<Note> _notes = [];
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadNotes();
  }
  
  void _loadNotes() {
    final json = _prefs.getString(_key);
    if (json != null) {
      final list = jsonDecode(json) as List;
      _notes = list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _saveNotes() async {
    final json = jsonEncode(_notes.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, json);
  }
  
  List<Note> getAllNotes() => List.unmodifiable(_notes);
  
  List<Note> getNotesForPaper(String paperId) =>
    _notes.where((n) => n.paperId == paperId).toList();
  
  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    await _saveNotes();
  }
  
  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      _notes[idx] = note;
      await _saveNotes();
    }
  }
  
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _saveNotes();
  }
}
