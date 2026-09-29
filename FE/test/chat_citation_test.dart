import 'package:flutter_test/flutter_test.dart';
import 'package:paper_chat/features/chat/widgets/message_bubble.dart';
import 'package:paper_chat/models/chat_message.dart';

void main() {
  group('Chat Clickable Citations Transform Tests', () {
    test('Transforms single citation [4] to markdown link', () {
      const input = 'Tối ưu hóa cân bằng diễn ra nhanh hơn gấp 72 lần [4].';
      final output = MessageBubble.transformCitationsToMarkdownLinks(input);
      expect(
        output,
        'Tối ưu hóa cân bằng diễn ra nhanh hơn gấp 72 lần [\\[4\\]](cite-source:4).',
      );
    });

    test('Transforms adjacent pair citations [1][2] to independent markdown links', () {
      const input = 'bộ giải vận chuyển (T3D) [1][2].';
      final output = MessageBubble.transformCitationsToMarkdownLinks(input);
      expect(
        output,
        'bộ giải vận chuyển (T3D) [\\[1\\]](cite-source:1)[\\[2\\]](cite-source:2).',
      );
    });

    test('Transforms multiple adjacent citations [1][2][4]', () {
      const input = 'hồ sơ bán kính của dòng [1][2][4].';
      final output = MessageBubble.transformCitationsToMarkdownLinks(input);
      expect(
        output,
        'hồ sơ bán kính của dòng [\\[1\\]](cite-source:1)[\\[2\\]](cite-source:2)[\\[4\\]](cite-source:4).',
      );
    });

    test('Does not transform regular markdown links like [Website](https://...)', () {
      const input = 'Xem thêm tại [Website](https://example.com) và [1].';
      final output = MessageBubble.transformCitationsToMarkdownLinks(input);
      expect(
        output,
        'Xem thêm tại [Website](https://example.com) và [\\[1\\]](cite-source:1).',
      );
    });

    test('Does not re-transform already transformed citations like [\\[1\\]](cite:b0)', () {
      const input = 'Tham khảo [\\[1\\]](cite:b0) và nguồn mới [2].';
      final output = MessageBubble.transformCitationsToMarkdownLinks(input);
      expect(
        output,
        'Tham khảo [\\[1\\]](cite:b0) và nguồn mới [\\[2\\]](cite-source:2).',
      );
    });
  });

  group('Citation Model Extension Tests', () {
    test('Citation holds sourceIndex, fileName and chunkOrder', () {
      const citation = Citation(
        paperId: '12',
        page: 2,
        excerpt: 'Đoạn trích dẫn mô hình AI...',
        label: '[1]',
        sourceIndex: 1,
        fileName: 'DESC_Surrogate.pdf',
        chunkOrder: 3,
      );

      expect(citation.sourceIndex, 1);
      expect(citation.fileName, 'DESC_Surrogate.pdf');
      expect(citation.chunkOrder, 3);
      expect(citation.page, 2);
      expect(citation.label, '[1]');
    });
  });

  group('Clean Excerpt For Display Tests', () {
    test('Cleans technical cite syntax [\\[1\\]](cite:b0) to clean citation [1]', () {
      const input = 'optimization loops [\\[1\\]](cite:b0)[\\[2\\]](cite:b1)[\\[3\\]](cite:b2).';
      final output = MessageBubble.cleanExcerptForDisplay(input);
      expect(output, 'optimization loops [1][2][3].');
    });

    test('Preserves bold authors markdown **Tác giả**: without corruption', () {
      const input = '**Tác giả**: R Michael Churchill, Matt Landreman\n\n## Abstract';
      final output = MessageBubble.cleanExcerptForDisplay(input);
      expect(output, '**Tác giả**: R Michael Churchill, Matt Landreman\n\n**Abstract**');
    });

    test('Converts leading # Title to bold **Title**', () {
      const input = '# AI-Accelerated Gyrokinetic Predictions\n\n**Tác giả**: Author';
      final output = MessageBubble.cleanExcerptForDisplay(input);
      expect(output, '**AI-Accelerated Gyrokinetic Predictions**\n\n**Tác giả**: Author');
    });
  });
}
