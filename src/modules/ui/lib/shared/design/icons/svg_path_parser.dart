import 'dart:ui';

import 'svg_path_scanner.dart';
import 'svg_path_segments.dart';

const String _moveLetters = 'Mm';
const String _closeLetters = 'Zz';

List<PathSegment> parseSvgPathData(String pathData) {
  return _SvgPathInterpreter(SvgPathScanner(pathData)).readAll();
}

Path buildSvgPath(List<PathSegment> segments, PathFillType fillType) {
  final path = Path()..fillType = fillType;

  for (final segment in segments) {
    segment.addTo(path);
  }

  return path;
}

class _SvgPathInterpreter {
  _SvgPathInterpreter(this._scanner);

  final SvgPathScanner _scanner;
  final List<PathSegment> _segments = [];
  Offset _current = Offset.zero;
  Offset _subpathStart = Offset.zero;
  Offset? _previousQuadraticControl;

  List<PathSegment> readAll() {
    while (!_scanner.isFinished) {
      final letter = _scanner.readCommandLetter();

      _requireMoveFirst(letter);
      _readCommand(letter);
    }

    return List.unmodifiable(_segments);
  }

  void _requireMoveFirst(String letter) {
    if (_segments.isEmpty && !_moveLetters.contains(letter)) {
      throw FormatException('SVG path data must start with a moveto', letter);
    }
  }

  void _readCommand(String letter) {
    if (_closeLetters.contains(letter)) {
      _append(const CloseSegment(), _subpathStart);
      return;
    }

    _readArguments(letter);

    final repeatedLetter = switch (letter) {
      'M' => 'L',
      'm' => 'l',
      _ => letter,
    };

    while (_scanner.isNumberNext) {
      _readArguments(repeatedLetter);
    }
  }

  void _readArguments(String letter) {
    final isRelative = letter.toLowerCase() == letter;
    final origin = isRelative ? _current : Offset.zero;

    switch (letter.toUpperCase()) {
      case 'M':
        _moveTo(_readPoint(origin));
      case 'L':
        final end = _readPoint(origin);
        _append(LineSegment(end), end);
      case 'H':
        final end = Offset(origin.dx + _scanner.readNumber(), _current.dy);
        _append(LineSegment(end), end);
      case 'V':
        final end = Offset(_current.dx, origin.dy + _scanner.readNumber());
        _append(LineSegment(end), end);
      case 'C':
        _cubicTo(origin);
      case 'Q':
        final control = _readPoint(origin);
        _quadraticTo(control, _readPoint(origin));
      case 'T':
        final control = _reflectedQuadraticControl();
        _quadraticTo(control, _readPoint(origin));
      case 'A':
        _arcTo(origin);
    }
  }

  Offset _readPoint(Offset origin) {
    final x = _scanner.readNumber();
    final y = _scanner.readNumber();

    return origin + Offset(x, y);
  }

  void _moveTo(Offset end) {
    _append(MoveSegment(end), end);
    _subpathStart = end;
  }

  void _cubicTo(Offset origin) {
    final firstControl = _readPoint(origin);
    final secondControl = _readPoint(origin);
    final end = _readPoint(origin);

    _append(
      CubicSegment(
        firstControl: firstControl,
        secondControl: secondControl,
        end: end,
      ),
      end,
    );
  }

  void _quadraticTo(Offset control, Offset end) {
    _append(QuadraticSegment(control: control, end: end), end);
    _previousQuadraticControl = control;
  }

  Offset _reflectedQuadraticControl() {
    final previousControl = _previousQuadraticControl;

    if (previousControl == null) {
      return _current;
    }

    return _current * 2 - previousControl;
  }

  void _arcTo(Offset origin) {
    final radiusX = _scanner.readNumber().abs();
    final radiusY = _scanner.readNumber().abs();
    final rotation = _scanner.readNumber();
    final size = _scanner.readFlag() ? ArcSize.large : ArcSize.small;
    final sweep = _scanner.readFlag()
        ? ArcSweep.clockwise
        : ArcSweep.counterclockwise;
    final end = _readPoint(origin);

    _append(
      ArcSegment(
        radius: Radius.elliptical(radiusX, radiusY),
        rotation: rotation,
        size: size,
        sweep: sweep,
        end: end,
      ),
      end,
    );
  }

  void _append(PathSegment segment, Offset end) {
    _segments.add(segment);
    _current = end;
    _previousQuadraticControl = null;
  }
}
