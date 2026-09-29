import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/document_reference.dart';
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
  bool _isContinuousMode = true;
  String? _highlightedCitationText;
  String? _highlightedCitationRefKey;
  String? _highlightedCitationLabel;
  int _citationJumpTrigger = 0;

  Paper? get currentPaper => _currentPaper;
  bool get isContinuousMode => _isContinuousMode;
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
  String? get highlightedCitationRefKey => _highlightedCitationRefKey;
  String? get highlightedCitationLabel => _highlightedCitationLabel;
  int get citationJumpTrigger => _citationJumpTrigger;
  List<DocumentReference> get references => _currentPaper?.references ?? const [];

  DocumentReference? findReference(String refKey) {
    if (_currentPaper == null) return null;
    final clean = refKey.trim().toLowerCase();
    final normalized = clean.replaceAll(RegExp(r'^[#b]+'), '');
    for (final ref in _currentPaper!.references) {
      final refLower = ref.refKey.toLowerCase();
      final k = refLower.replaceAll(RegExp(r'^[#b]+'), '');
      if (refLower == clean ||
          refLower == 'b$clean' ||
          ref.label.toLowerCase() == clean ||
          (normalized.isNotEmpty && k == normalized)) {
        return ref;
      }
    }
    return null;
  }

  void toggleContinuousMode() {
    _isContinuousMode = !_isContinuousMode;
    notifyListeners();
  }

  void setContinuousMode(bool value) {
    if (_isContinuousMode != value) {
      _isContinuousMode = value;
      notifyListeners();
    }
  }

  void notifyPaperUpdated() {
    notifyListeners();
  }

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

  void navigateToCitation(int page, String? excerpt, {String? targetRefKey, String? targetLabel}) {
    if (_currentPaper == null) return;
    _currentPage = page.clamp(0, totalPages - 1);
    _highlightedCitationPage = _currentPage;
    _highlightedCitationText = excerpt;
    _highlightedCitationRefKey = targetRefKey;
    _highlightedCitationLabel = targetLabel;
    _citationJumpTrigger++;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 3000), () {
      _highlightedCitationPage = null;
      _highlightedCitationText = null;
      _highlightedCitationRefKey = null;
      _highlightedCitationLabel = null;
      notifyListeners();
    });
  }

  int? findPageMentioningCitation(String refKey, String label) {
    if (_currentPaper == null) return null;
    final cleanKey = refKey.trim().toLowerCase();
    final stripped = cleanKey.replaceAll(RegExp(r'^[#b]+'), '');
    final cleanLabel = label.trim();

    final patterns = [
      if (cleanKey.isNotEmpty) 'cite:$cleanKey',
      if (stripped.isNotEmpty) 'cite:b$stripped',
      if (stripped.isNotEmpty) 'cite:$stripped',
      if (cleanLabel.isNotEmpty) '[$cleanLabel]',
      if (cleanLabel.isNotEmpty) '[\\$cleanLabel]',
      if (cleanLabel.isNotEmpty) '[\\[$cleanLabel\\]]',
      if (cleanLabel.isNotEmpty) '[$cleanLabel](',
    ];

    // Priority 1: Search main content pages (skip bibliography/references section itself)
    for (int i = 0; i < _currentPaper!.pages.length; i++) {
      final secTitle = _currentPaper!.pages[i].sectionTitle.toLowerCase();
      if (secTitle.contains('reference') || secTitle.contains('tài liệu tham khảo')) {
        continue;
      }
      final content = _currentPaper!.pages[i].content;
      for (final p in patterns) {
        if (content.toLowerCase().contains(p.toLowerCase())) {
          return i;
        }
      }
    }

    // Priority 2: Fallback to all pages if not found in main body
    for (int i = 0; i < _currentPaper!.pages.length; i++) {
      final content = _currentPaper!.pages[i].content;
      for (final p in patterns) {
        if (content.toLowerCase().contains(p.toLowerCase())) {
          return i;
        }
      }
    }
    return null;
  }

  bool jumpToCitationByReference(String refKey, String label) {
    final page = findPageMentioningCitation(refKey, label);
    if (page != null) {
      final excerpt = label.isNotEmpty ? '[$label]' : null;
      navigateToCitation(
        page,
        excerpt,
        targetRefKey: refKey,
        targetLabel: label,
      );
      return true;
    }
    return false;
  }
}
