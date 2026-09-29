import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/features/reader/reader_view_model.dart';
import 'package:paper_chat/features/reader/widgets/references_panel.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/models/document_reference.dart';
import 'package:paper_chat/models/paper.dart';
import 'package:paper_chat/services/settings_repository.dart';

class MockSettingsRepository extends SettingsRepository {
  @override
  AppLanguage get language => AppLanguage.vi;
  @override
  AppThemeMode get themeMode => AppThemeMode.light;
  @override
  double get readerFontSize => 14.0;
  @override
  double get chatFontSize => 14.0;
  @override
  bool get reduceMotion => false;
}

void main() {
  group('References Navigation & Panel Tests', () {
    late Paper testPaper;
    late ReaderViewModel readerVM;
    late SettingsViewModel settingsVM;

    setUp(() {
      final ref1 = DocumentReference(
        refKey: 'b0',
        label: '1',
        title: 'Attention Is All You Need',
        authors: 'Vaswani, A., Shazeer, N.',
        year: 2017,
        venue: 'NeurIPS',
        doi: '10.48550/arXiv.1706.03762',
      );
      final ref2 = DocumentReference(
        refKey: 'b1',
        label: '2',
        title: 'Deep Residual Learning for Image Recognition',
        authors: 'He, K., Zhang, X.',
        year: 2016,
        venue: 'CVPR',
        doi: '10.1109/CVPR.2016.90',
      );

      testPaper = Paper(
        id: '1',
        title: 'Transformer Survey',
        authors: ['Author A'],
        year: 2023,
        abstractText: 'Survey of transformers',
        tags: ['AI'],
        collection: 'Research',
        pages: [
          const PaperPage(
            pageNumber: 1,
            sectionTitle: 'Introduction',
            content: 'Transformers were introduced in [1](cite:b0) for NLP tasks.',
          ),
          const PaperPage(
            pageNumber: 2,
            sectionTitle: 'Related Work',
            content: 'Residual connections [2](cite:b1) are widely adopted in deep networks.',
          ),
        ],
        references: [ref1, ref2],
      );

      readerVM = ReaderViewModel();
      readerVM.openPaper(testPaper);

      settingsVM = SettingsViewModel(MockSettingsRepository());
    });

    test('ReaderViewModel finds page mentioning citation accurately', () {
      final pageForRef1 = readerVM.findPageMentioningCitation('b0', '1');
      expect(pageForRef1, 0);

      final pageForRef2 = readerVM.findPageMentioningCitation('b1', '2');
      expect(pageForRef2, 1);

      final notFound = readerVM.findPageMentioningCitation('b99', '99');
      expect(notFound, isNull);
    });

    test('ReaderViewModel jumpToCitationByReference triggers navigation', () {
      final initialTrigger = readerVM.citationJumpTrigger;
      final success = readerVM.jumpToCitationByReference('b1', '2');
      expect(success, isTrue);
      expect(readerVM.currentPage, 1);
      expect(readerVM.highlightedCitationText, '[2]');
      expect(readerVM.highlightedCitationRefKey, 'b1');
      expect(readerVM.highlightedCitationLabel, '2');
      expect(readerVM.citationJumpTrigger, initialTrigger + 1);

      // Repeated jump increments trigger again
      readerVM.jumpToCitationByReference('b1', '2');
      expect(readerVM.citationJumpTrigger, initialTrigger + 2);
    });

    test('ReaderViewModel findPageMentioningCitation prioritizes paper body over References section', () {
      final paperWithBiblio = Paper(
        id: '2',
        title: 'Paper With Biblio',
        authors: ['Author X'],
        year: 2024,
        abstractText: 'Test',
        tags: [],
        collection: 'Test',
        pages: [
          const PaperPage(
            pageNumber: 1,
            sectionTitle: 'Section 1',
            content: 'We use the methodology described in [17](cite:b16) for calculations.',
          ),
          const PaperPage(
            pageNumber: 2,
            sectionTitle: 'References',
            content: '[17] S Ando. (2026). arXiv:2603.04267',
          ),
        ],
        references: [],
      );

      final vm = ReaderViewModel();
      vm.openPaper(paperWithBiblio);

      // Should find page 0 (Section 1) instead of page 1 (References)
      final foundPage = vm.findPageMentioningCitation('b16', '17');
      expect(foundPage, 0);
    });

    testWidgets('ReferencesPanel renders references list and filters by search query', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              AppColorsExtension.light,
            ],
          ),
          home: Scaffold(
            body: ReferencesPanel(
              settingsVM: settingsVM,
              paper: testPaper,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and list
      expect(find.text('Tài liệu tham khảo'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('Attention Is All You Need'), findsOneWidget);
      expect(find.text('Deep Residual Learning for Image Recognition'), findsOneWidget);

      // Search for 'Residual'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Residual');
      await tester.pumpAndSettle();

      expect(find.text('Deep Residual Learning for Image Recognition'), findsOneWidget);
      expect(find.text('Attention Is All You Need'), findsNothing);
    });
  });
}
