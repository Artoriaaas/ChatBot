import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$(.+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!));
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
