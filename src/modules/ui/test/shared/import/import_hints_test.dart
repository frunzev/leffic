import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/import_draft.dart';
import 'package:leffic/shared/import/import_hints.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/property.dart';
import 'import_fakes.dart';

void main() {
  test('sourceStepHint property gives the first thing still missing', () {
    forAll(
      (random) => (
        oneOf<DraftReading>(random, [
          SourceMissing(reason: 'Missing ${wordOf(random)}'),
          SourceReady(source: generatedSource(random)),
        ]),
        oneOf(random, ImportSourceKind.values),
        generatedChoices(random),
      ),
      (example) {
        final (reading, kind, choices) = example;
        final hint = sourceStepHint(
          reading: reading,
          kind: kind,
          choices: choices,
        );
        final String? expected = switch (reading) {
          SourceMissing(:final reason) => reason,
          SourceReady()
              when kind == ImportSourceKind.text &&
                  !choices.isAnythingRequested =>
            'Choose something to generate.',
          SourceReady() => null,
        };

        expect(hint, expected);
      },
    );
  });

  test('reviewStepHint property wants text and something to generate', () {
    forAll(
      (random) => (
        oneOf(random, ['', ' \n', 'Kept ${wordOf(random)}']),
        generatedChoices(random),
      ),
      (example) {
        final (reviewedText, choices) = example;
        final hint = reviewStepHint(
          reviewedText: reviewedText,
          choices: choices,
        );

        if (reviewedText.trim().isEmpty) {
          expect(hint, 'Keep some text to generate from.');
          return;
        }

        expect(
          hint,
          choices.isAnythingRequested ? null : 'Choose something to generate.',
        );
      },
    );
  });
}
