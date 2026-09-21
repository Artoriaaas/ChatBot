class PaperPage {
  final int pageNumber;
  final String sectionTitle;
  final String content;
  
  const PaperPage({
    required this.pageNumber,
    required this.sectionTitle,
    required this.content,
  });
}

enum PaperStatus { unread, reading, completed }

class Paper {
  final String id;
  final String title;
  final List<String> authors;
  final int year;
  final String abstractText; // 'abstract' is reserved
  final List<String> tags;
  final String collection;
  bool isFavorite;
  PaperStatus status;
  final List<PaperPage> pages;
  
  Paper({
    required this.id,
    required this.title,
    required this.authors,
    required this.year,
    required this.abstractText,
    required this.tags,
    required this.collection,
    this.isFavorite = false,
    this.status = PaperStatus.unread,
    required this.pages,
  });
  
  int get totalPages => pages.length;
  
  String get authorsShort {
    if (authors.length <= 2) return authors.join(' & ');
    return '${authors.first} et al.';
  }
}
