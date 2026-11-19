import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_bookmark_button.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'file_fakes.dart';

void main() {
  test('bookmarkLabel property offers to remove only the page marked', () {
    forAll(
      (random) =>
          (integerBetween(random, 1, 300), generatedBookmarkedPage(random)),
      (example) {
        final (pageInView, bookmarkedPage) = example;
        final label = bookmarkLabel(
          pageInView: pageInView,
          bookmarkedPage: bookmarkedPage,
        );
        final isMarked = pageInView == bookmarkedPage;

        expect(label, contains('$pageInView'));
        expect(label.startsWith('Remove the bookmark'), isMarked);
      },
    );
  });

  testWidgets('FileBookmarkButton property toggles the page in view', (
    tester,
  ) async {
    for (final (pageInView, bookmarkedPage, brightness) in examplesOf((random) {
      final pageInView = integerBetween(random, 1, 300);

      return (
        pageInView,
        oneOf(random, [null, pageInView, pageInView + 1]),
        oneOf(random, Brightness.values),
      );
    }, runs: 10)) {
      final remembered = <int>[];
      var forgetCount = 0;
      final colors = DesignColors.forBrightness(brightness);
      final label = bookmarkLabel(
        pageInView: pageInView,
        bookmarkedPage: bookmarkedPage,
      );

      await tester.pumpWidget(
        hostedInTheme(
          Center(
            child: FileBookmarkButton(
              pageInView: pageInView,
              bookmarkedPage: bookmarkedPage,
              onRemember: remembered.add,
              onForget: () => forgetCount++,
            ),
          ),
          brightness: brightness,
        ),
      );

      final isMarked = pageInView == bookmarkedPage;
      final icon = tester.widget<DesignIcon>(find.byType(DesignIcon));
      final buttonBox = tester.getRect(find.byType(FileBookmarkButton));
      final iconButton = tester.widget<DesignIconButton>(
        find.byType(DesignIconButton),
      );

      expect(icon.icon, DesignIcons.bookmark);
      expect(icon.size, 18);
      expect(icon.color, isMarked ? colors.brand : colors.inkSecondary);
      expect(buttonBox.size, const Size.square(40));
      expect(iconButton.variant, ButtonVariant.quiet);
      expect(iconButton.borderRadius, 10);

      await tester.tap(find.bySemanticsLabel(label));

      expect(forgetCount, isMarked ? 1 : 0);
      expect(remembered, isMarked ? isEmpty : [pageInView]);
    }
  });
}
