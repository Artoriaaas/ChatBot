import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Hỗ trợ công thức toán dạng khối độc lập: $$ E = mc^2 $$
class BlockMathSyntax extends md.InlineSyntax {
  BlockMathSyntax() : super(r'\$\$([\s\S]+?)\$\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math-block', match[1]!.trim()));
    return true;
  }
}

/// Hỗ trợ công thức toán nội dòng: $x + y$
class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'(?<!\$)\$(?!\$)([^\$\n]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!.trim()));
    return true;
  }
}

class MathBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;

  MathBuilder({this.textStyle});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    try {
      return Math.tex(
        element.textContent,
        textStyle: textStyle ?? preferredStyle,
        mathStyle: MathStyle.text,
      );
    } catch (e) {
      return Text(
        '\$${element.textContent}\$',
        style: preferredStyle?.copyWith(color: Colors.red),
      );
    }
  }
}

class MathBlockBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;

  MathBlockBuilder({this.textStyle});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    try {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            element.textContent,
            textStyle: textStyle ?? preferredStyle,
            mathStyle: MathStyle.display,
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '\$\$${element.textContent}\$\$',
          style: preferredStyle?.copyWith(color: Colors.red),
        ),
      );
    }
  }
}

