import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/src/delta_to_markdown.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final _deltaToMd = DeltaToMarkdown();

List<md.Node> parseMarkdown(String markdown, [md.Document? document]) {
  return (document ?? _mdDocument)
      .parseLines(const LineSplitter().convert(markdown));
}

/// checks the if rendered html of both inputs are equal
void expectEqualMarkdown(String actual, String match, [md.Document? document]) {
  final actualNodes = parseMarkdown(actual, document);
  final matchNodes = parseMarkdown(match, document);
  final actualHtml = md.HtmlRenderer().render(actualNodes);
  final matchHtml = md.HtmlRenderer()
      .render(matchNodes)
      .replaceAll(RegExp('alt=".*?" />'), 'alt="" />');

  expect(actualHtml, matchHtml);
}

void deltaOpsToMdCheck(
  List<Operation> ops,
  String expected, [
  DeltaToMarkdown? deltaToMd,
  md.Document? document,
]) {
  final delta = Delta();
  for (final op in ops) {
    delta.push(op);
  }
  final actual = (deltaToMd ?? _deltaToMd).convert(delta);
  expectEqualMarkdown(actual, expected, document);
}

/// https://github.com/TarekkMA/markdown_quill/issues/33
/// Lists not working. Every bullet is converted to `1.` instead of `2.`, `3.`...
void main() {
  test('multiple ordered list items should be numbered sequentially', () {
    final ops = [
      Operation.insert('One'),
      Operation.insert('\n', Attribute.ol.toJson()),
      Operation.insert('Two '),
      Operation.insert('\n', Attribute.ol.toJson()),
      Operation.insert('Three'),
      Operation.insert('\n', Attribute.ol.toJson()),
      Operation.insert('Four'),
      Operation.insert('\n', Attribute.ol.toJson()),
      Operation.insert('Five'),
      Operation.insert('\n', Attribute.ol.toJson()),
      Operation.insert('Six'),
      Operation.insert('\n', Attribute.ol.toJson()),
    ];
    const expected = '''
1. One
2. Two 
3. Three
4. Four
5. Five
6. Six
    ''';

    deltaOpsToMdCheck(ops, expected);
  });
}
