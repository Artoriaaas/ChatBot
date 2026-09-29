class DocumentReference {
  final String refKey;
  final String label;
  final String? title;
  final String? authors;
  final int? year;
  final String? venue;
  final String? doi;
  final String? url;
  final String? rawCitationText;

  const DocumentReference({
    required this.refKey,
    required this.label,
    this.title,
    this.authors,
    this.year,
    this.venue,
    this.doi,
    this.url,
    this.rawCitationText,
  });

  factory DocumentReference.fromJson(Map<String, dynamic> json) {
    return DocumentReference(
      refKey: json['refKey'] as String? ?? json['ref_key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      title: json['title'] as String?,
      authors: json['authors'] as String?,
      year: (json['year'] as num?)?.toInt(),
      venue: json['venue'] as String?,
      doi: json['doi'] as String?,
      url: json['url'] as String?,
      rawCitationText: json['rawCitationText'] as String? ?? json['raw_citation_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refKey': refKey,
      'label': label,
      'title': title,
      'authors': authors,
      'year': year,
      'venue': venue,
      'doi': doi,
      'url': url,
      'rawCitationText': rawCitationText,
    };
  }

  String get effectiveUrl {
    if (url != null && url!.trim().isNotEmpty) return url!.trim();
    if (doi != null && doi!.trim().isNotEmpty) {
      final clean = doi!.trim();
      return clean.startsWith('http') ? clean : 'https://doi.org/$clean';
    }
    return '';
  }
}
