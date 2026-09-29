import 'package:flutter_test/flutter_test.dart';
import 'package:paper_chat/models/document_reference.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/features/reader/reader_view_model.dart';

void main() {
  group('DocumentReference and Clickable Citations Tests', () {
    test('DocumentReference parses from backend JSON correctly', () {
      final json = {
        'refKey': 'b0',
        'label': '1',
        'title': 'Outside the Closed World: On Using Machine Learning for Network Intrusion Detection',
        'authors': 'R Sommer, V Paxson',
        'year': 2010,
        'venue': '2010 IEEE Symposium on Security and Privacy',
        'doi': '10.1109/SP.2010.25',
        'url': 'https://doi.org/10.1109/SP.2010.25',
        'rawCitationText': 'R. Sommer and V. Paxson...',
      };

      final ref = DocumentReference.fromJson(json);

      expect(ref.refKey, 'b0');
      expect(ref.label, '1');
      expect(ref.title, contains('Outside the Closed World'));
      expect(ref.authors, 'R Sommer, V Paxson');
      expect(ref.year, 2010);
      expect(ref.venue, contains('IEEE Symposium'));
      expect(ref.doi, '10.1109/SP.2010.25');
      expect(ref.effectiveUrl, 'https://doi.org/10.1109/SP.2010.25');
    });

    test('ReaderViewModel finds reference by refKey or normalized key', () {
      final ref1 = DocumentReference(
        refKey: 'b0',
        label: '1',
        title: 'Paper One',
        authors: 'Author A',
        year: 2020,
      );
      final ref2 = DocumentReference(
        refKey: 'b1',
        label: '2',
        title: 'Paper Two',
        authors: 'Author B',
        year: 2021,
      );

      final paper = Paper(
        id: '1',
        title: 'Test Paper',
        authors: ['Author X'],
        year: 2022,
        abstractText: 'Test abstract',
        tags: ['AI'],
        collection: 'Test',
        pages: [
          const PaperPage(
            pageNumber: 1,
            sectionTitle: 'Section 1',
            content: 'Attack patterns [1](cite:b0) and [2](cite:b1).',
          ),
          const PaperPage(
            pageNumber: 2,
            sectionTitle: 'References',
            content: '[1] Paper One\n[2] Paper Two',
          ),
        ],
        references: [ref1, ref2],
      );

      final vm = ReaderViewModel();
      vm.openPaper(paper);

      expect(vm.references.length, 2);
      expect(vm.findReference('b0')?.title, 'Paper One');
      expect(vm.findReference('#b0')?.title, 'Paper One');
      expect(vm.findReference('0')?.title, 'Paper One');
      expect(vm.findReference('1')?.title, 'Paper One');
      expect(vm.findReference('b1')?.title, 'Paper Two');
      expect(vm.findReference('b99'), isNull);
    });
  });
}
