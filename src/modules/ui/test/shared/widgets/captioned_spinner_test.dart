import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/spinner.dart';
import 'package:leffic/shared/widgets/captioned_spinner.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

void main() {
  testWidgets('CaptionedSpinner property shows its label beside a spinner', (
    tester,
  ) async {
    for (final label in examplesOf(wordOf, runs: 5)) {
      await tester.pumpWidget(hostedPlainly(CaptionedSpinner(label: label)));

      expect(find.text(label), findsOneWidget);
      expect(find.byType(Spinner), findsOneWidget);
    }
  });
}
