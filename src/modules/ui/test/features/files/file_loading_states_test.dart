import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_failure.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/state_block.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

void main() {
  testWidgets('FileFailure property names the file, the reason and a retry', (
    tester,
  ) async {
    for (final (fileName, reason) in examplesOf(
      (random) => (wordOf(random), 'Reason ${wordOf(random)}'),
      runs: 5,
    )) {
      var retryCount = 0;

      await tester.pumpWidget(
        hostedPlainly(
          FileFailure(
            fileName: fileName,
            reason: reason,
            onRetry: () => retryCount++,
          ),
        ),
      );
      await tester.tap(find.text('Try again'));

      final state = tester.widget<StateBlock>(find.byType(StateBlock));

      expect(state.icon, DesignIcons.failure);
      expect(state.title, "Couldn't open $fileName");
      expect(state.text, reason);
      expect(find.text("Couldn't open $fileName"), findsOneWidget);
      expect(find.text(reason), findsOneWidget);
      expect(retryCount, 1);
    }
  });
}
