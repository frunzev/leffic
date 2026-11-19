import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/toast.dart';
import 'package:leffic/shared/import/generation_progress.dart';
import 'package:leffic/shared/import/generation_tasks.dart';
import 'package:leffic/shared/import/import_messages.dart';
import 'package:leffic/shared/office/missing_libreoffice.dart';

import '../../support/property.dart';

void main() {
  test('generationProgressMessage property names the source it reads', () {
    forAll((random) => '${wordOf(random)}.pdf', (sourceLabel) {
      final message = generationProgressMessage(sourceLabel);

      expect(message.tone, ToastTone.progress);
      expect(message.title, 'Generating from $sourceLabel');
      expect(message.detail, 'About a minute. You can keep working.');
    });
  });

  test('kindOutcomeMessage property says which kind is ready or failed', () {
    forAll(
      (random) => GeneratedKindOutcome(
        kind: oneOf(random, GeneratedKind.values),
        outcome: oneOf(random, [TaskOutcome.succeeded, TaskOutcome.failed]),
      ),
      (kindOutcome) {
        final message = kindOutcomeMessage(kindOutcome);
        final kindLabel = kindOutcome.kind.label;

        if (kindOutcome.outcome == TaskOutcome.succeeded) {
          expect(message.tone, ToastTone.success);
          expect(message.title, '$kindLabel ready');
          expect(message.detail, isNull);
          return;
        }

        expect(message.tone, ToastTone.failure);
        expect(
          message.title,
          "Couldn't generate the ${kindLabel.toLowerCase()}",
        );
        expect(message.detail, 'The source could not be processed. Try again.');
      },
    );
  });

  test('failure messages property name the source and pass the reason', () {
    forAll((random) => (wordOf(random), 'Reason ${wordOf(random)}'), (example) {
      final (sourceLabel, reason) = example;
      final reading = readingFailureMessage(sourceLabel, reason);
      final generation = generationFailureMessage(sourceLabel, reason);

      expect(reading.tone, ToastTone.failure);
      expect(reading.title, "Couldn't read $sourceLabel");
      expect(reading.detail, reason);
      expect(generation.tone, ToastTone.failure);
      expect(generation.title, "Couldn't generate from $sourceLabel");
      expect(generation.detail, reason);
    });
  });

  test('readingFailureMessage property sends a missing LibreOffice to '
      'Settings', () {
    forAll((random) => (wordOf(random), '/${tokenOf(random)}/soffice'), (
      example,
    ) {
      final (sourceLabel, binary) = example;
      final reason = 'LibreOffice is not installed at $binary';

      expect(
        readingFailureMessage(sourceLabel, reason),
        same(missingLibreOfficeMessage),
      );
    });
  });

  test('upload messages property name the uploaded file', () {
    forAll((random) => '${wordOf(random)}.txt', (fileName) {
      final progress = uploadProgressMessage(fileName);
      final success = uploadSuccessMessage(fileName);
      final failure = uploadFailureMessage(fileName);

      expect(progress.tone, ToastTone.progress);
      expect(progress.title, 'Uploading $fileName');
      expect(success.tone, ToastTone.success);
      expect(success.title, '$fileName uploaded');
      expect(failure.tone, ToastTone.failure);
      expect(failure.title, "Couldn't upload $fileName");
      expect(failure.detail, 'The file could not be saved. Try again.');
    });
  });
}
