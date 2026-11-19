import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/libreoffice_setup.dart';

import '../../support/property.dart';
import 'libreoffice_fakes.dart';

List<int> _imageBytesOf(Random random) {
  final length = integerBetween(random, 1, 4096);

  return [for (var index = 0; index < length; index++) random.nextInt(256)];
}

List<int> _cutsOf(Random random, int length) {
  final cuts = <int>{0, length};
  final extraCuts = integerBetween(random, 0, 8);

  for (var cut = 0; cut < extraCuts; cut++) {
    cuts.add(integerBetween(random, 0, length));
  }

  return cuts.toList()..sort();
}

Future<List<LibreOfficeState>> _downloadedStates({
  required LibreOfficeSetup setup,
  required PacedImageServer server,
  required List<int> cuts,
}) async {
  final states = <LibreOfficeState>[];

  setup.addListener(() => states.add(setup.value));

  final downloading = setup.download();

  for (var index = 1; index < cuts.length; index++) {
    server.send(cuts[index - 1], cuts[index]);
    await pumpEventQueue();
  }

  await server.finish();
  await downloading;

  return states;
}

void main() {
  test('downloadedPercent property stays within 0..100 and grows', () {
    forAll(
      (random) {
        final total = integerBetween(random, 1, 1 << 30);
        final first = integerBetween(random, 0, total);

        return (total, first, integerBetween(random, first, total));
      },
      (example) {
        final (total, smaller, larger) = example;
        final smallerPercent = downloadedPercent(smaller, total);

        expect(smallerPercent, inInclusiveRange(0, 100));
        expect(
          downloadedPercent(larger, total),
          greaterThanOrEqualTo(smallerPercent),
        );
        expect(downloadedPercent(total, total), 100);
      },
    );
  });

  test('LibreOfficeSetup property walks from missing to installed', () async {
    for (final (imageBytes, cutSeed) in examplesOf(
      (random) => (_imageBytesOf(random), random.nextInt(1 << 30)),
      runs: 10,
    )) {
      final server = PacedImageServer(imageBytes);
      final installer = await installerServedBy(
        server: server,
        tools: FakeImageTools(),
      );
      final setup = LibreOfficeSetup(installer);

      expect(setup.value, isA<LibreOfficeChecking>());

      await setup.refresh();

      expect(setup.value, isA<LibreOfficeMissing>());

      final states = await _downloadedStates(
        setup: setup,
        server: server,
        cuts: _cutsOf(Random(cutSeed), imageBytes.length),
      );
      final percents = [
        for (final state in states)
          if (state is LibreOfficeDownloading) state.percent,
      ];

      expect(states.first, isA<LibreOfficeDownloading>());
      expect(states[states.length - 2], isA<LibreOfficeInstalling>());
      expect(states.last, isA<LibreOfficeInstalled>());
      expect(percents.first, 0);
      expect(percents.last, 100);

      for (var index = 1; index < percents.length; index++) {
        expect(percents[index], greaterThan(percents[index - 1]));
      }
    }
  });

  test('LibreOfficeSetup property fails with the reason and retries', () async {
    for (final failingStep in ImageStep.values) {
      final tools = FakeImageTools(failingStep: failingStep);
      final server = PacedImageServer([1, 2, 3]);
      final setup = LibreOfficeSetup(
        await installerServedBy(server: server, tools: tools),
      );

      await _downloadedStates(setup: setup, server: server, cuts: [0, 3]);

      final failure = setup.value;

      expect(failure, isA<LibreOfficeFailed>());
      expect(
        (failure as LibreOfficeFailed).reason,
        contains('${failingStep.name} refused'),
      );

      tools.failingStep = null;

      await _downloadedStates(setup: setup, server: server, cuts: [0, 3]);

      expect(setup.value, isA<LibreOfficeInstalled>());
    }
  });

  test('LibreOfficeSetup property refuses to start twice', () async {
    final server = PacedImageServer([4, 5, 6]);
    final setup = LibreOfficeSetup(
      await installerServedBy(server: server, tools: FakeImageTools()),
    );
    final downloading = setup.download();

    await expectLater(setup.download(), throwsStateError);
    await expectLater(setup.remove(), throwsStateError);

    server.send(0, 3);
    await server.finish();
    await downloading;

    expect(setup.value, isA<LibreOfficeInstalled>());
  });

  test('LibreOfficeSetup property returns to missing on remove', () async {
    final server = PacedImageServer([7, 8, 9]);
    final setup = LibreOfficeSetup(
      await installerServedBy(server: server, tools: FakeImageTools()),
    );

    await _downloadedStates(setup: setup, server: server, cuts: [0, 3]);
    await setup.remove();

    expect(setup.value, isA<LibreOfficeMissing>());

    await setup.refresh();

    expect(setup.value, isA<LibreOfficeMissing>());
  });
}
