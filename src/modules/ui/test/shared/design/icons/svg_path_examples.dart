import 'dart:math';
import 'dart:ui';

import 'package:leffic/shared/design/icons/svg_path_segments.dart';

import '../../../support/property.dart';

const int _largestEighths = 4000;
const int _largestSegmentCount = 14;
const List<String> _separators = [' ', ',', ' , ', '\n', '  '];

double coordinateOf(Random random) {
  return integerBetween(random, -_largestEighths, _largestEighths) / 8;
}

double boundedCoordinateOf(Random random, double side) {
  return integerBetween(random, 0, (side * 8).round()) / 8;
}

Offset pointOf(Random random) {
  return Offset(coordinateOf(random), coordinateOf(random));
}

Radius arcRadiusOf(Random random) {
  final horizontal = integerBetween(random, 1, _largestEighths) / 8;
  final vertical = integerBetween(random, 1, _largestEighths) / 8;

  return Radius.elliptical(horizontal, vertical);
}

class _SegmentWalk {
  _SegmentWalk(this._random);

  final Random _random;
  Offset _current = Offset.zero;
  Offset _subpathStart = Offset.zero;

  PathSegment next() {
    final segment = _segmentOfKind(integerBetween(_random, 0, 7));

    _current = switch (segment) {
      MoveSegment(:final end) => end,
      LineSegment(:final end) => end,
      CubicSegment(:final end) => end,
      QuadraticSegment(:final end) => end,
      ArcSegment(:final end) => end,
      CloseSegment() => _subpathStart,
    };

    if (segment is MoveSegment) {
      _subpathStart = segment.end;
    }

    return segment;
  }

  PathSegment _segmentOfKind(int kind) {
    return switch (kind) {
      0 => MoveSegment(pointOf(_random)),
      1 => LineSegment(Offset(coordinateOf(_random), _current.dy)),
      2 => LineSegment(Offset(_current.dx, coordinateOf(_random))),
      3 => CubicSegment(
        firstControl: pointOf(_random),
        secondControl: pointOf(_random),
        end: pointOf(_random),
      ),
      4 => QuadraticSegment(control: pointOf(_random), end: pointOf(_random)),
      5 => ArcSegment(
        radius: arcRadiusOf(_random),
        rotation: coordinateOf(_random),
        size: oneOf(_random, ArcSize.values),
        sweep: oneOf(_random, ArcSweep.values),
        end: pointOf(_random),
      ),
      6 => const CloseSegment(),
      _ => LineSegment(pointOf(_random)),
    };
  }
}

List<PathSegment> segmentsOf(Random random) {
  final walk = _SegmentWalk(random);
  final count = integerBetween(random, 0, _largestSegmentCount);
  final first = walk.next();
  final segments = <PathSegment>[
    if (first is MoveSegment) first else MoveSegment(pointOf(random)),
  ];

  for (var index = 0; index < count; index++) {
    segments.add(walk.next());
  }

  return segments;
}

class PathDataWriter {
  PathDataWriter(this._random);

  final Random _random;
  final StringBuffer _buffer = StringBuffer();
  bool _isAfterNumber = false;

  void command(String letter) {
    if (_buffer.isNotEmpty) {
      _buffer.write(oneOf(_random, ['', ..._separators]));
    }

    _buffer.write(letter);
    _isAfterNumber = false;
  }

  void numbers(List<double> values) {
    for (final value in values) {
      _writeNumber(value);
    }
  }

  void point(Offset point) {
    numbers([point.dx, point.dy]);
  }

  void flag(int flag) {
    final separators = _isAfterNumber ? _separators : ['', ..._separators];

    _buffer.write(oneOf(_random, separators));
    _buffer.write(flag);
    _isAfterNumber = false;
  }

  String text() => _buffer.toString();

  void _writeNumber(double value) {
    final digits = _spellingOf(value);
    final mayTouch = !_isAfterNumber || digits.startsWith('-');

    _buffer.write(mayTouch ? oneOf(_random, ['', ..._separators]) : ' ');
    _buffer.write(digits);
    _isAfterNumber = true;
  }

  String _spellingOf(double value) {
    final plain = value.toString();

    if (_random.nextBool() && plain.endsWith('.0')) {
      return plain.substring(0, plain.length - 2);
    }

    if (_random.nextBool() && plain.startsWith('0.')) {
      return plain.substring(1);
    }

    if (_random.nextBool() && plain.startsWith('-0.')) {
      return '-${plain.substring(2)}';
    }

    return plain;
  }
}

int arcSizeFlagOf(ArcSize size) => size == ArcSize.large ? 1 : 0;

int arcSweepFlagOf(ArcSweep sweep) => sweep == ArcSweep.clockwise ? 1 : 0;

enum PathNotation { absolute, relative }

class _NotationWriter {
  _NotationWriter(this._writer, this._notation);

  final PathDataWriter _writer;
  final PathNotation _notation;
  Offset _current = Offset.zero;
  Offset _subpathStart = Offset.zero;

  void write(PathSegment segment) {
    switch (segment) {
      case MoveSegment(:final end):
        _command('M');
        _point(end);
        _subpathStart = end;
      case LineSegment(:final end) when end.dy == _current.dy:
        _command('H');
        _writer.numbers([end.dx - _origin.dx]);
      case LineSegment(:final end) when end.dx == _current.dx:
        _command('V');
        _writer.numbers([end.dy - _origin.dy]);
      case LineSegment(:final end):
        _command('L');
        _point(end);
      case CubicSegment(:final firstControl, :final secondControl, :final end):
        _command('C');
        _point(firstControl);
        _point(secondControl);
        _point(end);
      case QuadraticSegment(:final control, :final end):
        _command('Q');
        _point(control);
        _point(end);
      case ArcSegment():
        _command('A');
        _writer.numbers([segment.radius.x, segment.radius.y]);
        _writer.numbers([segment.rotation]);
        _writer.flag(arcSizeFlagOf(segment.size));
        _writer.flag(arcSweepFlagOf(segment.sweep));
        _point(segment.end);
      case CloseSegment():
        _command('Z');
    }

    _current = switch (segment) {
      MoveSegment(:final end) => end,
      LineSegment(:final end) => end,
      CubicSegment(:final end) => end,
      QuadraticSegment(:final end) => end,
      ArcSegment(:final end) => end,
      CloseSegment() => _subpathStart,
    };
  }

  Offset get _origin {
    return switch (_notation) {
      PathNotation.absolute => Offset.zero,
      PathNotation.relative => _current,
    };
  }

  void _command(String upperLetter) {
    final letter = switch (_notation) {
      PathNotation.absolute => upperLetter,
      PathNotation.relative => upperLetter.toLowerCase(),
    };

    _writer.command(letter);
  }

  void _point(Offset point) {
    _writer.point(point - _origin);
  }
}

String pathDataOf(
  List<PathSegment> segments,
  Random random,
  PathNotation notation,
) {
  final writer = PathDataWriter(random);
  final notationWriter = _NotationWriter(writer, notation);

  for (final segment in segments) {
    notationWriter.write(segment);
  }

  return writer.text();
}
