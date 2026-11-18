import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Style of a (selectable) reader text: the innermost span that sets a
/// font size. Since Task 11 reader blocks are `SelectableText`, whose
/// style lives in the text span, not in a `Text` widget.
TextStyle readerTextStyle(WidgetTester tester, String text) {
  final finder = find.text(text);
  final widget = tester.widget(finder);
  if (widget is Text) return widget.style!;
  final editable = widget as EditableText;
  final span = editable.controller.buildTextSpan(
    context: tester.element(finder),
    withComposing: false,
  );
  // visitChildren skips style-only spans, so walk the tree directly.
  TextStyle? found;
  void walk(InlineSpan s) {
    if (s.style?.fontSize != null) found = s.style;
    s.visitDirectChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(span);
  return found!;
}
