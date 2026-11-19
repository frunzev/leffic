import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/unit_details.dart';
import 'package:leffic/features/folders/unit_presentation.dart';

import '../../support/property.dart';
import 'folder_fakes.dart';

void main() {
  test('iconForUnitType property gives each type its own icon', () {
    final icons = {for (final type in UnitType.values) iconForUnitType(type)};

    expect(icons.length, UnitType.values.length);
  });

  test('unitNoun property names each type in its own lower case word', () {
    final nouns = {for (final type in UnitType.values) unitNoun(type)};

    expect(nouns.length, UnitType.values.length);

    for (final noun in nouns) {
      expect(noun, matches(RegExp(r'^[a-z]+$')));
    }
  });

  test('itemCountLabel property names the count with the right plural', () {
    forAll((random) => integerBetween(random, 0, 5000), (count) {
      final label = itemCountLabel(count);

      expect(label, startsWith('$count '));
      expect(label.endsWith('items'), count != 1);
    });
  });

  test('describeAge property counts whole calendar days back', () {
    forAll(
      (random) => (
        moment: generatedMoment(random),
        days: integerBetween(random, 2, 900),
        hour: integerBetween(random, 0, 23),
      ),
      (example) {
        final moment = example.moment;
        final now = DateTime(
          moment.year,
          moment.month,
          moment.day + example.days,
          example.hour,
        );

        expect(
          describeAge(moment: moment, now: now),
          '${example.days} days ago',
        );
      },
    );
  });

  test('describeAge property says today, yesterday, never the future', () {
    forAll(
      (random) => (
        moment: generatedMoment(random),
        hours: integerBetween(random, 0, 2000),
      ),
      (example) {
        final moment = example.moment;
        final sameDay = DateTime(moment.year, moment.month, moment.day, 23, 59);
        final nextDay = DateTime(moment.year, moment.month, moment.day + 1);
        final earlier = moment.subtract(Duration(hours: example.hours));

        expect(describeAge(moment: moment, now: sameDay), 'today');
        expect(describeAge(moment: moment, now: nextDay), 'yesterday');
        expect(describeAge(moment: moment, now: earlier), 'today');
      },
    );
  });

  test('countLabel property names the count with the right plural', () {
    forAll(
      (random) => (
        count: integerBetween(random, 0, 5000),
        noun: oneOf(random, ['card', 'question', 'item']),
      ),
      (example) {
        final label = countLabel(count: example.count, noun: example.noun);

        expect(label, startsWith('${example.count} ${example.noun}'));
        expect(label.endsWith('s'), example.count != 1);
      },
    );
  });

  test('fileSizeLabel property rounds to one decimal of KB or MB', () {
    forAll((random) => integerBetween(random, 0, 900000000), (sizeBytes) {
      final label = fileSizeLabel(sizeBytes);
      final match = RegExp(r'^(\d+\.\d) (KB|MB)$').firstMatch(label)!;
      final shown = double.parse(match.group(1)!);
      final isMegabytes = match.group(2) == 'MB';
      final unitBytes = isMegabytes ? 1000000 : 1000;

      expect(isMegabytes, sizeBytes >= 1000000);
      expect((shown - sizeBytes / unitBytes).abs(), lessThanOrEqualTo(0.05));
    });
  });

  test('unitMetaLine property describes each unit like the design', () {
    forAll(
      (random) => (
        unit: FolderUnit.fromJson(generatedUnitJson(random, 'unit')),
        now: generatedMoment(random),
      ),
      (example) {
        final unit = example.unit;
        final now = example.now;
        final details = unit.details;
        final expected = switch (details) {
          FolderDetails() =>
            '${itemCountLabel(details.itemCount)} · edited '
                '${describeAge(moment: details.editedAt, now: now)}',
          DeckDetails() => countLabel(count: details.cardCount, noun: 'card'),
          TestDetails() => countLabel(
            count: details.questionCount,
            noun: 'question',
          ),
          NoteDetails() => '${details.readingMinutes} min read',
          FileDetails(sizeBytes: null) => unit.extension.toUpperCase(),
          FileDetails(:final sizeBytes?) =>
            '${unit.extension.toUpperCase()} · ${fileSizeLabel(sizeBytes)}',
        };

        expect(unitMetaLine(unit: unit, now: now), expected);
      },
    );
  });

  test('unitMetaLine property names an extensionless file a File', () {
    forAll((random) => integerBetween(random, 0, 90000000), (sizeBytes) {
      final unit = FolderUnit.fromJson({
        'id': 'unit',
        'name': 'notes',
        'type': 'file',
        'created_at': '2026-11-18 12:00:00',
        'size_bytes': sizeBytes,
      });

      expect(
        unitMetaLine(unit: unit, now: DateTime(2026, 11, 18)),
        'File · ${fileSizeLabel(sizeBytes)}',
      );
    });
  });

  test('unitMetaLine property writes the design examples exactly', () {
    final now = DateTime(2026, 11, 18, 12);
    final designUnits = {
      'folder': {
        'item_count': 6,
        'edited_at': pythonTimestamp(DateTime(2026, 11, 16, 9)),
      },
      'flashcard_deck': {'card_count': 30, 'due_count': 12},
      'test': {'question_count': 30, 'due_count': 7},
      'note': {'reading_minutes': 4},
      'file': {'extension': 'pdf', 'size_bytes': 1200000},
    };
    final lines = [
      for (final entry in designUnits.entries)
        unitMetaLine(
          unit: FolderUnit.fromJson({
            'id': entry.key,
            'name': entry.key,
            'type': entry.key,
            'created_at': '2026-11-01 08:00:00',
            ...entry.value,
          }),
          now: now,
        ),
    ];

    expect(lines, [
      '6 items · edited 2 days ago',
      '30 cards',
      '30 questions',
      '4 min read',
      'PDF · 1.2 MB',
    ]);
  });

  test('unitDueCount property counts due work only in decks and tests', () {
    forAll((random) => FolderUnit.fromJson(generatedUnitJson(random, 'u')), (
      unit,
    ) {
      final expected = switch (unit.details) {
        DeckDetails(:final dueCount) => dueCount,
        TestDetails(:final dueCount) => dueCount,
        _ => 0,
      };

      expect(unitDueCount(unit), expected);
    });
  });

  test('dueBadgeLabel property names the due count like .unit-badge', () {
    forAll((random) => integerBetween(random, 1, 999), (dueCount) {
      expect(dueBadgeLabel(dueCount), '$dueCount due');
    });
  });
}
