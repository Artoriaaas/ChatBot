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
  final String? documentId;
  String title;
  List<String> authors;
  int year;
  String abstractText; // 'abstract' is reserved
  List<String> tags;
  String collection;
  bool isFavorite;
  PaperStatus status;
  final List<PaperPage> pages;
  String indexStatus;
  int indexProgress;

  String? journal;
  String? publisher;
  String? doi;
  String? volume;
  String? issue;
  String? pagesInfo;
  String? keywords;

  Paper({
    required this.id,
    this.documentId,
    required this.title,
    required this.authors,
    required this.year,
    required this.abstractText,
    required this.tags,
    required this.collection,
    this.isFavorite = false,
    this.status = PaperStatus.unread,
    required this.pages,
    this.indexStatus = 'Completed',
    this.indexProgress = 100,
    this.journal,
    this.publisher,
    this.doi,
    this.volume,
    this.issue,
    this.pagesInfo,
    this.keywords,
  });

  void updateMetadata({
    String? title,
    List<String>? authors,
    int? year,
    String? abstractText,
    List<String>? tags,
    String? collection,
    String? journal,
    String? publisher,
    String? doi,
    String? volume,
    String? issue,
    String? pagesInfo,
    String? keywords,
  }) {
    if (title != null) this.title = title;
    if (authors != null) this.authors = authors;
    if (year != null) this.year = year;
    if (abstractText != null) this.abstractText = abstractText;
    if (tags != null) this.tags = tags;
    if (collection != null) this.collection = collection;
    if (journal != null) this.journal = journal;
    if (publisher != null) this.publisher = publisher;
    if (doi != null) this.doi = doi;
    if (volume != null) this.volume = volume;
    if (issue != null) this.issue = issue;
    if (pagesInfo != null) this.pagesInfo = pagesInfo;
    if (keywords != null) this.keywords = keywords;
  }

  int get totalPages => pages.length;

  String get authorsShort {
    if (authors.length <= 2) return authors.join(' & ');
    return '${authors.first} et al.';
  }
}
