import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/paper.dart';

class ReaderViewModel extends ChangeNotifier {
  Paper? _currentPaper;
  int _currentPage = 0;
  double _zoomLevel = 1.0;
  String _searchQuery = '';
  List<int> _searchResults = [];
  int _currentSearchResultIndex = -1;
  String? _selectedText;
  final Map<String, Set<String>> _highlights = {};
  int? _highlightedCitationPage;
  String? _highlightedCitationText;

  Paper? get currentPaper => _currentPaper;
  PaperPage? get currentPageContent => 
      _currentPaper != null && _currentPage >= 0 && _currentPage < _currentPaper!.pages.length 
          ? _currentPaper!.pages[_currentPage] 
          : null;
  int get currentPage => _currentPage;
  int get totalPages => _currentPaper?.totalPages ?? 0;
  double get zoomLevel => _zoomLevel;
  String get searchQuery => _searchQuery;
  List<int> get searchResults => _searchResults;
  int get currentSearchResultIndex => _currentSearchResultIndex;
  String? get selectedText => _selectedText;
  Set<String> get currentHighlights => _currentPaper != null ? _highlights[_currentPaper!.id] ?? {} : {};
  int? get highlightedCitationPage => _highlightedCitationPage;
  String? get highlightedCitationText => _highlightedCitationText;

  void openPaper(Paper paper) {
    _currentPaper = paper;
    _currentPage = 0;
    _zoomLevel = 1.0;
    _searchQuery = '';
    _searchResults = [];
    _currentSearchResultIndex = -1;
    _selectedText = null;
    _highlightedCitationPage = null;
    _highlightedCitationText = null;
    paper.status = PaperStatus.reading;
    notifyListeners();
  }

  void goToPage(int page) {
    if (_currentPaper == null) return;
    _currentPage = page.clamp(0, totalPages - 1);
    notifyListeners();
  }

  void setZoom(double zoom) {
    _zoomLevel = zoom.clamp(0.5, 2.0);
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _searchResults = [];
    _currentSearchResultIndex = -1;
    if (query.isNotEmpty && _currentPaper != null) {
      final lowerQuery = query.toLowerCase();
      for (int i = 0; i < _currentPaper!.pages.length; i++) {
        if (_currentPaper!.pages[i].content.toLowerCase().contains(lowerQuery)) {
          _searchResults.add(i);
        }
      }
      if (_searchResults.isNotEmpty) {
        _currentSearchResultIndex = 0;
        goToPage(_searchResults[0]);
      }
    }
    notifyListeners();
  }

  void nextSearchResult() {
    if (_searchResults.isNotEmpty) {
      _currentSearchResultIndex = (_currentSearchResultIndex + 1) % _searchResults.length;
      goToPage(_searchResults[_currentSearchResultIndex]);
    }
  }

  void prevSearchResult() {
    if (_searchResults.isNotEmpty) {
      _currentSearchResultIndex = (_currentSearchResultIndex - 1 + _searchResults.length) % _searchResults.length;
      goToPage(_searchResults[_currentSearchResultIndex]);
    }
  }

  void selectText(String text) {
    _selectedText = text;
    notifyListeners();
  }

  void clearSelection() {
    _selectedText = null;
    notifyListeners();
  }

  void addHighlight(String text) {
    if (_currentPaper == null) return;
    _highlights.putIfAbsent(_currentPaper!.id, () => {});
    _highlights[_currentPaper!.id]!.add(text);
    notifyListeners();
  }

  void removeHighlight(String text) {
    if (_currentPaper == null) return;
    _highlights[_currentPaper!.id]?.remove(text);
    notifyListeners();
  }

  void navigateToCitation(int page, String? excerpt) {
    if (_currentPaper == null) return;
    _currentPage = page.clamp(0, totalPages - 1);
    _highlightedCitationPage = _currentPage;
    _highlightedCitationText = excerpt;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      _highlightedCitationPage = null;
      _highlightedCitationText = null;
      notifyListeners();
    });
  }
}
