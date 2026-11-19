import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/cloze_text.dart';

import '../../support/hosting.dart';

const double _cardInnerWidth = 718;

String reassembledCloze(InlineSpan span) {
  final buffer = StringBuffer();

  span.visitChildren((child) {
    if (child is TextSpan) {
      buffer.write(child.text ?? '');
    }

    if (child is WidgetSpan) {
      buffer.write((child.child as ClozeMark).hiddenPart);
    }

    return true;
  });

  return buffer.toString();
}

RichText clozeParagraphOf(WidgetTester tester) {
  return tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byType(ClozeText),
          matching: find.byType(RichText),
        ),
      )
      .first;
}

Future<void> pumpAtCardWidth(WidgetTester tester, Widget view) async {
  useDesktopSurface(tester);
  await tester.pumpWidget(
    hostedPlainly(
      Center(
        child: SizedBox(width: _cardInnerWidth, child: view),
      ),
    ),
  );
}
