import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const String _lineBreak = '\n';

String withoutLineBreaks(String text) {
  return text.replaceAll(_lineBreak, '');
}

class _ShownTextMatcher {
  const _ShownTextMatcher(this.expectedText);

  final String expectedText;

  bool matches(Widget widget) {
    if (widget is! RichText) {
      return false;
    }

    final shownText = withoutLineBreaks(widget.text.toPlainText());

    return shownText == withoutLineBreaks(expectedText);
  }
}

Finder findShownText(String text) {
  return find.byWidgetPredicate(_ShownTextMatcher(text).matches);
}

TextStyle renderedStyleOf(WidgetTester tester, String text) {
  final paragraph = tester.widget<RichText>(findShownText(text));

  return paragraph.text.style ?? const TextStyle();
}
