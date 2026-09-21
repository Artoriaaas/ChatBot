import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/mock_paper_repository.dart';

enum SortMode { yearDesc, yearAsc, titleAsc, titleDesc }

class LibraryViewModel extends ChangeNotifier {
  final MockPaperRepository _repo;
  
  LibraryViewModel(this._repo);
  
  String _searchQuery = '';
  String? _selectedTag;
  String? _selectedCollection;
  SortMode _sortMode = SortMode.yearDesc;
  bool _showFavoritesOnly = false;
  
  String get searchQuery => _searchQuery;
  set searchQuery(String v) { _searchQuery = v; notifyListeners(); }

  // All papers in the repo. Used by AppShell to resolve a paper by id when
  // navigating from Notes without changing the current filter state.
  List<Paper> get papers => _repo.getAllPapers();
  
  String? get selectedTag => _selectedTag;
  set selectedTag(String? v) { _selectedTag = v; notifyListeners(); }
  
  String? get selectedCollection => _selectedCollection;
  set selectedCollection(String? v) { _selectedCollection = v; notifyListeners(); }
  
  SortMode get sortMode => _sortMode;
  set sortMode(SortMode v) { _sortMode = v; notifyListeners(); }
  
  bool get showFavoritesOnly => _showFavoritesOnly;
  set showFavoritesOnly(bool v) { _showFavoritesOnly = v; notifyListeners(); }
  
  List<String> get allTags => _repo.getAllPapers().expand((p) => p.tags).toSet().toList()..sort();
  List<String> get allCollections => _repo.getAllPapers().map((p) => p.collection).toSet().toList()..sort();
  
  List<Paper> get filteredPapers {
    var papers = _repo.getAllPapers().toList();
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      papers = papers.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.abstractText.toLowerCase().contains(q) ||
        p.authors.any((a) => a.toLowerCase().contains(q)) ||
        p.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }
    
    // Apply tag filter
    if (_selectedTag != null) {
      papers = papers.where((p) => p.tags.contains(_selectedTag)).toList();
    }
    
    // Apply collection filter
    if (_selectedCollection != null) {
      papers = papers.where((p) => p.collection == _selectedCollection).toList();
    }
    
    // Apply favorites filter
    if (_showFavoritesOnly) {
      papers = papers.where((p) => p.isFavorite).toList();
    }
    
    // Apply sort
    papers.sort((a, b) {
      switch (_sortMode) {
        case SortMode.yearDesc:
          return b.year.compareTo(a.year);
        case SortMode.yearAsc:
          return a.year.compareTo(b.year);
        case SortMode.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortMode.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });
    
    return papers;
  }
  
  void toggleFavorite(String paperId) {
    final paper = _repo.getPaperById(paperId);
    if (paper != null) {
      paper.isFavorite = !paper.isFavorite;
      notifyListeners();
    }
  }
  
  void clearFilters() {
    _searchQuery = '';
    _selectedTag = null;
    _selectedCollection = null;
    _showFavoritesOnly = false;
    _sortMode = SortMode.yearDesc;
    notifyListeners();
  }
}
