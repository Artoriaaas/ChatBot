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

  String? get arxivId {
    if (doi != null && doi!.toLowerCase().contains('arxiv')) {
      final m = RegExp(
        r'(?:arxiv\.|\/|^)?([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?|[a-z\-]+(?:\.[a-z]{2})?\/[0-9]{7})',
        caseSensitive: false,
      ).firstMatch(doi!);
      if (m != null) return m.group(1);
    }
    if (url != null && url!.toLowerCase().contains('arxiv')) {
      final m = RegExp(
        r'arxiv\.org\/(?:abs|pdf)\/([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?|[a-z\-]+(?:\.[a-z]{2})?\/[0-9]{7})',
        caseSensitive: false,
      ).firstMatch(url!);
      if (m != null) return m.group(1);
    }
    final textToCheck = '${venue ?? ''} ${rawCitationText ?? ''} ${title ?? ''}';
    final m = RegExp(
      r'arxiv[:\s\/]+([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?|[a-z\-]+(?:\.[a-z]{2})?\/[0-9]{7})',
      caseSensitive: false,
    ).firstMatch(textToCheck);
    if (m != null) return m.group(1);
    return null;
  }

  bool get isArxiv => arxivId != null;

  String get effectiveUrl {
    if (url != null && url!.trim().isNotEmpty) {
      final u = url!.trim();
      return u.startsWith('http') ? u : 'https://$u';
    }
    if (doi != null && doi!.trim().isNotEmpty) {
      final clean = doi!.trim();
      if (clean.toLowerCase().startsWith('arxiv:')) {
        return 'https://arxiv.org/abs/${clean.substring(6).trim()}';
      }
      return clean.startsWith('http') ? clean : 'https://doi.org/$clean';
    }
    final arx = arxivId;
    if (arx != null) {
      return 'https://arxiv.org/abs/$arx';
    }
    return '';
  }

  /// Tự động trích xuất danh sách DocumentReference từ văn bản mục References
  static List<DocumentReference> parseFromText(String text) {
    final list = <DocumentReference>[];
    final lines = text.split('\n');
    final reg = RegExp(
      r'^(?:<a\s+id="ref-([^"]+)">\s*<\/a>)?(?:\*\*)?\[([0-9A-Za-z]+)\](?:\*\*)?\s*(.*)$',
      caseSensitive: false,
    );

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = reg.firstMatch(line);
      if (match != null) {
        final refKey = match.group(1) ?? 'b${list.length}';
        final label = match.group(2) ?? '${list.length + 1}';
        final body = match.group(3)?.trim() ?? '';

        int? year;
        final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(body);
        if (yearMatch != null) {
          year = int.tryParse(yearMatch.group(1)!);
        }

        String? extractedUrl;
        final arxivM = RegExp(
          r'arxiv[:\s\/]+([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?|[a-z\-]+(?:\.[a-z]{2})?\/[0-9]{7})',
          caseSensitive: false,
        ).firstMatch(body);
        if (arxivM != null) {
          extractedUrl = 'https://arxiv.org/abs/${arxivM.group(1)}';
        } else {
          final urlM = RegExp(r'https?:\/\/[^\s\)]+').firstMatch(body);
          if (urlM != null) {
            extractedUrl = urlM.group(0);
          }
        }

        final cleanBody = body.replaceAll(RegExp(r'<a\s+id="[^"]*">\s*<\/a>', caseSensitive: false), '').trim();

        // Tách tiêu đề nếu có định dạng Markdown *Title*
        String? title;
        final titleItalicMatch = RegExp(r'\*([^*]+)\*').firstMatch(cleanBody);
        if (titleItalicMatch != null) {
          title = titleItalicMatch.group(1)?.trim();
        }

        list.add(
          DocumentReference(
            refKey: refKey,
            label: label,
            title: title ?? cleanBody,
            year: year,
            url: extractedUrl,
            rawCitationText: cleanBody,
          ),
        );
      }
    }
    return list;
  }
}
