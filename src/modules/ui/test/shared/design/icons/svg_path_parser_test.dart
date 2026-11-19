import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/icons/svg_path_parser.dart';
import 'package:leffic/shared/design/icons/svg_path_segments.dart';

import '../../../support/property.dart';
import 'svg_path_examples.dart';

const String _commandLetters = 'MmLlHhVvCcQqTtAaZz';
const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const double _box = 120;

typedef _WrittenPath = (List<PathSegment> segments, String pathData);

_WrittenPath _writtenIn(Random random, PathNotation notation) {
  final segments = segmentsOf(random);

  return (segments, pathDataOf(segments, random, notation));
}

Offset _boundedPointOf(Random random) {
  return Offset(
    boundedCoordinateOf(random, _box),
    boundedCoordinateOf(random, _box),
  );
}

List<PathSegment> _boundedSegmentsOf(Random random) {
  final count = integerBetween(random, 1, 10);
  final segments = <PathSegment>[MoveSegment(_boundedPointOf(random))];

  for (var index = 0; index < count; index++) {
    segments.add(
      oneOf(random, [
        LineSegment(_boundedPointOf(random)),
        CubicSegment(
          firstControl: _boundedPointOf(random),
          secondControl: _boundedPointOf(random),
          end: _boundedPointOf(random),
        ),
        QuadraticSegment(
          control: _boundedPointOf(random),
          end: _boundedPointOf(random),
        ),
        const CloseSegment(),
      ]),
    );
  }

  return segments;
}

void main() {
  test('parseSvgPathData property round-trips absolute commands', () {
    forAll((random) => _writtenIn(random, PathNotation.absolute), (example) {
      final (segments, pathData) = example;

      expect(parseSvgPathData(pathData), segments, reason: pathData);
    });
  });

  test('parseSvgPathData property reads relative commands as absolute', () {
    forAll(
      (random) {
        final segments = segmentsOf(random);

        return (
          pathDataOf(segments, random, PathNotation.absolute),
          pathDataOf(segments, random, PathNotation.relative),
        );
      },
      (example) {
        final (absoluteData, relativeData) = example;

        expect(
          parseSvgPathData(relativeData),
          parseSvgPathData(absoluteData),
          reason: '$relativeData\n$absoluteData',
        );
      },
    );
  });

  test('parseSvgPathData property reflects the last control for T', () {
    forAll(
      (random) =>
          (pointOf(random), pointOf(random), pointOf(random), pointOf(random)),
      (example) {
        final (start, control, middle, end) = example;
        final writer = PathDataWriter(Random(fixedSeed))
          ..command('M')
          ..point(start)
          ..command('Q')
          ..point(control)
          ..point(middle)
          ..command('T')
          ..point(end);

        expect(parseSvgPathData(writer.text()), [
          MoveSegment(start),
          QuadraticSegment(control: control, end: middle),
          QuadraticSegment(control: middle * 2 - control, end: end),
        ]);
      },
    );
  });

  test('parseSvgPathData property starts T at the point without a Q', () {
    forAll((random) => (pointOf(random), pointOf(random)), (example) {
      final (start, end) = example;
      final pathData = 'M${start.dx} ${start.dy}T${end.dx} ${end.dy}';

      expect(parseSvgPathData(pathData), [
        MoveSegment(start),
        QuadraticSegment(control: start, end: end),
      ]);
    });
  });

  test('parseSvgPathData property repeats a moveto as lines', () {
    forAll((random) => (pointOf(random), pointOf(random)), (example) {
      final (first, second) = example;
      final absolute = 'M${first.dx} ${first.dy} ${second.dx} ${second.dy}';
      final relative = 'm${first.dx} ${first.dy} ${second.dx} ${second.dy}';

      expect(parseSvgPathData(absolute), [
        MoveSegment(first),
        LineSegment(second),
      ]);
      expect(parseSvgPathData(relative), [
        MoveSegment(first),
        LineSegment(first + second),
      ]);
    });
  });

  test('parseSvgPathData property rejects every unknown command letter', () {
    final unknownLetters = [
      for (final letter in _alphabet.split(''))
        if (!_commandLetters.contains(letter)) letter,
    ];

    forAll((random) => oneOf(random, unknownLetters), (letter) {
      expect(() => parseSvgPathData('M0 0${letter}1 1'), throwsFormatException);
    });
  });

  test('parseSvgPathData property rejects data that does not move first', () {
    final drawingLetters = _commandLetters.replaceAll(RegExp('[Mm]'), '');

    forAll((random) => oneOf(random, drawingLetters.split('')), (letter) {
      expect(() => parseSvgPathData('${letter}1 1'), throwsFormatException);
    });
  });

  test('parseSvgPathData property rejects a command missing a number', () {
    forAll(
      (random) => oneOf(random, ['M1', 'M1 1L2', 'M1 1C1 2 3', 'M0 0A1 1 0 1']),
      (pathData) {
        expect(() => parseSvgPathData(pathData), throwsFormatException);
      },
    );
  });

  test('parseSvgPathData property rejects arc flags other than 0 or 1', () {
    forAll((random) => integerBetween(random, 2, 9), (flag) {
      expect(
        () => parseSvgPathData('M0 0A1 1 0 $flag 1 4 4'),
        throwsFormatException,
      );
    });
  });

  test('parseSvgPathData property reads empty data as no segments', () {
    forAll((random) => oneOf(random, ['', ' ', '\n', ' , ']), (pathData) {
      expect(parseSvgPathData(pathData), isEmpty);
    });
  });

  test('buildSvgPath property stays inside the box its points span', () {
    forAll(_boundedSegmentsOf, (segments) {
      final bounds = buildSvgPath(segments, PathFillType.nonZero).getBounds();

      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(_box));
      expect(bounds.bottom, lessThanOrEqualTo(_box));
    });
  });

  test('buildSvgPath property keeps the requested fill rule', () {
    forAll((random) => oneOf(random, PathFillType.values), (fillType) {
      final path = buildSvgPath(const [
        MoveSegment(Offset.zero),
        LineSegment(Offset(4, 0)),
        CloseSegment(),
      ], fillType);

      expect(path.fillType, fillType);
    });
  });
}
