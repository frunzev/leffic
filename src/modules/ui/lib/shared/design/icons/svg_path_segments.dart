import 'dart:ui';

enum ArcSize { small, large }

enum ArcSweep { counterclockwise, clockwise }

sealed class PathSegment {
  const PathSegment();

  void addTo(Path path);
}

final class MoveSegment extends PathSegment {
  const MoveSegment(this.end);

  final Offset end;

  @override
  void addTo(Path path) => path.moveTo(end.dx, end.dy);

  @override
  bool operator ==(Object other) => other is MoveSegment && other.end == end;

  @override
  int get hashCode => Object.hash(MoveSegment, end);
}

final class LineSegment extends PathSegment {
  const LineSegment(this.end);

  final Offset end;

  @override
  void addTo(Path path) => path.lineTo(end.dx, end.dy);

  @override
  bool operator ==(Object other) => other is LineSegment && other.end == end;

  @override
  int get hashCode => Object.hash(LineSegment, end);
}

final class CubicSegment extends PathSegment {
  const CubicSegment({
    required this.firstControl,
    required this.secondControl,
    required this.end,
  });

  final Offset firstControl;
  final Offset secondControl;
  final Offset end;

  @override
  void addTo(Path path) {
    path.cubicTo(
      firstControl.dx,
      firstControl.dy,
      secondControl.dx,
      secondControl.dy,
      end.dx,
      end.dy,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CubicSegment &&
        other.firstControl == firstControl &&
        other.secondControl == secondControl &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(firstControl, secondControl, end);
}

final class QuadraticSegment extends PathSegment {
  const QuadraticSegment({required this.control, required this.end});

  final Offset control;
  final Offset end;

  @override
  void addTo(Path path) {
    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }

  @override
  bool operator ==(Object other) {
    return other is QuadraticSegment &&
        other.control == control &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(control, end);
}

final class ArcSegment extends PathSegment {
  const ArcSegment({
    required this.radius,
    required this.rotation,
    required this.size,
    required this.sweep,
    required this.end,
  });

  final Radius radius;
  final double rotation;
  final ArcSize size;
  final ArcSweep sweep;
  final Offset end;

  @override
  void addTo(Path path) {
    path.arcToPoint(
      end,
      radius: radius,
      rotation: rotation,
      largeArc: size == ArcSize.large,
      clockwise: sweep == ArcSweep.clockwise,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ArcSegment &&
        other.radius == radius &&
        other.rotation == rotation &&
        other.size == size &&
        other.sweep == sweep &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(radius, rotation, size, sweep, end);
}

final class CloseSegment extends PathSegment {
  const CloseSegment();

  @override
  void addTo(Path path) => path.close();

  @override
  bool operator ==(Object other) => other is CloseSegment;

  @override
  int get hashCode => (CloseSegment).hashCode;
}
