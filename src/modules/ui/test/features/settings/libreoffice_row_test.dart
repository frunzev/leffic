import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/libreoffice_row.dart';
import 'package:leffic/features/settings/libreoffice_setup.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/meter.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'libreoffice_fakes.dart';

const String _purpose = 'Opens and reads Word, Excel and PowerPoint files';

LibreOfficeState _stateOf(Random random) {
  return oneOf(random, <LibreOfficeState>[
    const LibreOfficeChecking(),
    const LibreOfficeMissing(),
    LibreOfficeDownloading(integerBetween(random, 0, 100)),
    const LibreOfficeInstalling(),
    const LibreOfficeInstalled(),
    LibreOfficeFailed('Refused ${wordOf(random)}'),
  ]);
}

Future<ScriptedLibreOfficeSetup> _pumpRow(
  WidgetTester tester,
  LibreOfficeState state, {
  LibreOfficeState outcome = const LibreOfficeInstalled(),
}) async {
  final setup = ScriptedLibreOfficeSetup(state, outcome: outcome);

  await tester.pumpWidget(
    hostedPlainly(LibreOfficeRow(key: UniqueKey(), setup: setup)),
  );
  await tester.pump();

  return setup;
}

void _expectButtons(List<String> labels) {
  for (final label in ['Download', 'Remove', 'Try again']) {
    expect(
      find.widgetWithText(DesignButton, label),
      labels.contains(label) ? findsWidgets : findsNothing,
    );
  }
}

void main() {
  testWidgets('LibreOfficeRow property shows what each state allows', (
    tester,
  ) async {
    for (final state in examplesOf(_stateOf, runs: 18)) {
      final setup = await _pumpRow(tester, state);

      expect(find.text('LibreOffice'), findsOneWidget);
      expect(setup.refreshCount, 1);

      switch (state) {
        case LibreOfficeChecking():
          _expectButtons([]);
        case LibreOfficeMissing():
          expect(find.text('$_purpose. 299 MB download.'), findsOneWidget);
          _expectButtons(['Download']);
        case LibreOfficeDownloading(:final percent):
          final meter = tester.widget<MeterBlock>(find.byType(MeterBlock));

          expect(meter.fraction, percent / 100);
          expect(meter.endLabel, '$percent%');
          _expectButtons([]);
        case LibreOfficeInstalling():
          final meter = tester.widget<MeterBlock>(find.byType(MeterBlock));

          expect(meter.fraction, 1);
          expect(meter.startLabel, 'Installing');
          _expectButtons([]);
        case LibreOfficeInstalled():
          expect(find.text('$_purpose. Installed on this Mac.'), findsOne);
          _expectButtons(['Remove']);
        case LibreOfficeFailed(:final reason):
          expect(find.text(reason), findsOneWidget);
          _expectButtons(['Try again']);
      }
    }
  });

  testWidgets('LibreOfficeRow property announces how the download ended', (
    tester,
  ) async {
    for (final outcome in examplesOf(
      (random) => oneOf(random, <LibreOfficeState>[
        const LibreOfficeInstalled(),
        LibreOfficeFailed('Refused ${wordOf(random)}'),
      ]),
      runs: 6,
    )) {
      final setup = await _pumpRow(
        tester,
        const LibreOfficeMissing(),
        outcome: outcome,
      );

      await tester.tap(find.text('Download'));
      await tester.pump();

      expect(find.text('Downloading LibreOffice'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(setup.downloadCount, 1);
      expect(find.text('Downloading LibreOffice'), findsNothing);

      if (outcome is LibreOfficeFailed) {
        expect(find.text("Couldn't install LibreOffice"), findsOneWidget);
        expect(find.text(outcome.reason), findsWidgets);
      } else {
        expect(find.text('LibreOffice installed'), findsOneWidget);
      }
    }
  });

  testWidgets('LibreOfficeRow property removes LibreOffice on request', (
    tester,
  ) async {
    await _pumpRow(tester, const LibreOfficeInstalled());

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    _expectButtons(['Download']);
  });
}
