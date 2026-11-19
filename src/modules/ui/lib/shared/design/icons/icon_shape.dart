import 'dart:ui';

import 'svg_path_parser.dart';

class IconPath {
  const IconPath(this.data, {this.fillType = PathFillType.nonZero});

  final String data;
  final PathFillType fillType;

  Path toPath() => buildSvgPath(parseSvgPathData(data), fillType);
}

class IconShape {
  const IconShape({required this.viewBox, required this.paths});

  final Rect viewBox;
  final List<IconPath> paths;
}
