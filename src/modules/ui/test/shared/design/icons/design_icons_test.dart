import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/icons/icon_shape.dart';

import '../../../support/property.dart';

const String _designIconsFile = '../../../docs/design/icons.js';
const int _samplesPerContour = 400;
const double _edgeTolerance = 0.01;

final RegExp _iconEntry = RegExp(
  r'^  (\w+): \{\n    viewBox: "([^"]+)",\n    body: '
  r"'(.*?)',\n  \},",
  multiLine: true,
  dotAll: true,
);
final RegExp _pathElement = RegExp(r'<path([^>]*?)d="([^"]+)"');

typedef _DesignIcon = ({String viewBox, List<IconPath> paths});

Map<String, _DesignIcon> _readDesignIcons() {
  final source = File(_designIconsFile).readAsStringSync();
  final icons = <String, _DesignIcon>{};

  for (final entry in _iconEntry.allMatches(source)) {
    final paths = [
      for (final element in _pathElement.allMatches(entry.group(3) ?? ''))
        IconPath(
          element.group(2) ?? '',
          fillType: (element.group(1) ?? '').contains('evenodd')
              ? PathFillType.evenOdd
              : PathFillType.nonZero,
        ),
    ];

    icons[entry.group(1) ?? ''] = (viewBox: entry.group(2) ?? '', paths: paths);
  }

  return icons;
}

String _spelledViewBox(Rect viewBox) {
  final numbers = [viewBox.left, viewBox.top, viewBox.width, viewBox.height];

  return numbers.map((number) => number.round().toString()).join(' ');
}

Rect _drawnBoundsOf(Path path) {
  var bounds = Rect.zero;
  var isFirstPoint = true;

  for (final contour in path.computeMetrics()) {
    for (var step = 0; step <= _samplesPerContour; step++) {
      final distance = contour.length * step / _samplesPerContour;
      final position = contour.getTangentForOffset(distance)?.position;

      if (position == null) {
        continue;
      }

      final pointBounds = Rect.fromPoints(position, position);

      bounds = isFirstPoint ? pointBounds : bounds.expandToInclude(pointBounds);
      isFirstPoint = false;
    }
  }

  return bounds;
}

void main() {
  test('DesignIcons property holds exactly the icons of icons.js', () {
    final designIcons = _readDesignIcons();

    expect(designIcons, hasLength(32));
    expect(
      DesignIcons.values.map((icon) => icon.name).toSet(),
      designIcons.keys.toSet(),
    );
  });

  test('DesignIcons property copies each viewBox and path verbatim', () {
    final designIcons = _readDesignIcons();

    forAll((random) => oneOf(random, DesignIcons.values), (icon) {
      final designIcon = designIcons[icon.name];
      final shape = icon.shape;

      expect(_spelledViewBox(shape.viewBox), designIcon?.viewBox);
      expect(
        shape.paths.map((path) => (path.data, path.fillType)).toList(),
        designIcon?.paths.map((path) => (path.data, path.fillType)).toList(),
      );
    });
  });

  test('DesignIcons property draws every icon inside its viewBox', () {
    for (final icon in DesignIcons.values) {
      final viewBox = icon.shape.viewBox;
      final tolerance = viewBox.width * _edgeTolerance;

      for (final iconPath in icon.shape.paths) {
        final drawn = _drawnBoundsOf(iconPath.toPath());

        expect(drawn.isEmpty, isFalse, reason: icon.name);
        expect(
          viewBox.inflate(tolerance).contains(drawn.topLeft) &&
              viewBox.inflate(tolerance).contains(drawn.bottomRight),
          isTrue,
          reason: '${icon.name} draws $drawn outside $viewBox',
        );
      }
    }
  });

  test('viewBoxTransform property centres the viewBox inside the box', () {
    forAll(
      (random) => (
        Rect.fromLTWH(
          integerBetween(random, -960, 40).toDouble(),
          integerBetween(random, -960, 40).toDouble(),
          integerBetween(random, 1, 960).toDouble(),
          integerBetween(random, 1, 960).toDouble(),
        ),
        Size(
          integerBetween(random, 1, 64).toDouble(),
          integerBetween(random, 1, 64).toDouble(),
        ),
      ),
      (example) {
        final (viewBox, size) = example;
        final transform = viewBoxTransform(viewBox, size);
        final topLeft = MatrixUtils.transformPoint(transform, viewBox.topLeft);
        final bottomRight = MatrixUtils.transformPoint(
          transform,
          viewBox.bottomRight,
        );
        final fitted = Rect.fromPoints(topLeft, bottomRight);
        final scaleX = fitted.width / viewBox.width;
        final scaleY = fitted.height / viewBox.height;

        expect(scaleX, closeTo(scaleY, 1e-9));
        expect(fitted.center.dx, closeTo(size.width / 2, 1e-6));
        expect(fitted.center.dy, closeTo(size.height / 2, 1e-6));
        expect(
          fitted.width - size.width <= 1e-6 &&
              fitted.height - size.height <= 1e-6,
          isTrue,
        );
        expect(
          (fitted.width - size.width).abs() < 1e-6 ||
              (fitted.height - size.height).abs() < 1e-6,
          isTrue,
        );
      },
    );
  });

  testWidgets('DesignIcon property is the asked size in the text colour', (
    tester,
  ) async {
    for (final (icon, size, colorValue) in examplesOf(
      (random) => (
        oneOf(random, DesignIcons.values),
        integerBetween(random, 8, 48).toDouble(),
        integerBetween(random, 0, 0xFFFFFF),
      ),
      runs: 12,
    )) {
      final textColor = Color(0xFF000000 | colorValue);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(color: textColor),
              child: DesignIcon(icon, size: size),
            ),
          ),
        ),
      );

      final painted = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DesignIcon),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = painted.painter as ShapePainter;

      expect(tester.getSize(find.byType(DesignIcon)), Size.square(size));
      expect(painter.color, textColor);
      expect(painter.shape, same(icon.shape));
    }
  });

  testWidgets('DesignIcon property prefers an explicit colour', (tester) async {
    for (final icon in examplesOf(
      (random) => oneOf(random, DesignIcons.values),
      runs: 6,
    )) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(color: Color(0xFF000000)),
            child: Center(
              child: DesignIcon(icon, color: const Color(0xFF1A6FD4)),
            ),
          ),
        ),
      );

      final painted = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DesignIcon),
          matching: find.byType(CustomPaint),
        ),
      );

      expect((painted.painter as ShapePainter).color, const Color(0xFF1A6FD4));
      expect(tester.getSize(find.byType(DesignIcon)), const Size.square(20));
    }
  });
}
