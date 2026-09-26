import 'package:flutter_test/flutter_test.dart';
import 'package:paper_chat/services/doi_service.dart';

void main() {
  group('DoiService', () {
    test('cleanDoi handles raw, URL, and prefixed DOIs', () {
      expect(DoiService.cleanDoi('10.1038/nature12373'), '10.1038/nature12373');
      expect(DoiService.cleanDoi('https://doi.org/10.1038/nature12373'), '10.1038/nature12373');
      expect(DoiService.cleanDoi('http://doi.org/10.1038/nature12373'), '10.1038/nature12373');
      expect(DoiService.cleanDoi('https://dx.doi.org/10.1038/nature12373'), '10.1038/nature12373');
      expect(DoiService.cleanDoi('doi: 10.1038/nature12373'), '10.1038/nature12373');
      expect(DoiService.cleanDoi('  10.1038/nature12373  '), '10.1038/nature12373');
      expect(
        DoiService.cleanDoi('10.48550/arXiv.2609.29516v1[math.AC]'),
        '10.48550/arXiv.2609.29516',
      );
      expect(
        DoiService.cleanDoi('https://doi.org/10.48550/arXiv.astro-ph/9508025v2'),
        '10.48550/arXiv.astro-ph/9508025',
      );
    });

    test('isValidDoi accurately validates DOIs', () {
      expect(DoiService.isValidDoi('10.1038/nature12373'), isTrue);
      expect(DoiService.isValidDoi('https://doi.org/10.1145/3313831.3376727'), isTrue);
      expect(DoiService.isValidDoi('10.1109/CVPR.2019.00010'), isTrue);
      expect(DoiService.isValidDoi('invalid_doi_string'), isFalse);
      expect(DoiService.isValidDoi(''), isFalse);
      expect(DoiService.isValidDoi('   '), isFalse);
    });

    test('formatDisplay displays clean identifier as hyperlink text', () {
      expect(
        DoiService.formatDisplay('10.48550/arXiv.2609.29516v1[math.AC]'),
        'arXiv:2609.29516',
      );
      expect(
        DoiService.formatDisplay('10.48550/arXiv.astro-ph/9508025'),
        'arXiv:astro-ph/9508025',
      );
      expect(
        DoiService.formatDisplay('https://doi.org/10.1038/nature12373'),
        '10.1038/nature12373',
      );
      expect(
        DoiService.formatDisplay('doi: 10.1145/3313831.3376727'),
        '10.1145/3313831.3376727',
      );
    });
  });
}
