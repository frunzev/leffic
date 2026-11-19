import 'package:flutter/widgets.dart';

import '../../shared/design/design_divider.dart';
import '../../shared/design/design_metrics.dart';
import 'folder_panel.dart';

const Radius _outerCorner = Radius.circular(Radii.large);

BorderRadius unitRowCorners({required int index, required int count}) {
  if (index < 0 || index >= count) {
    throw ArgumentError.value(index, 'index', 'is not one of $count rows');
  }

  final top = index == 0 ? _outerCorner : Radius.zero;
  final bottom = index == count - 1 ? _outerCorner : Radius.zero;

  return BorderRadius.vertical(top: top, bottom: bottom);
}

List<Widget> withDividersBetween(List<Widget> rows) {
  final separatedRows = <Widget>[];

  for (final row in rows) {
    if (separatedRows.isNotEmpty) {
      separatedRows.add(const DesignDivider());
    }

    separatedRows.add(row);
  }

  return separatedRows;
}

class UnitList extends StatelessWidget {
  const UnitList({required this.rows, super.key});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return FolderPanel(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: withDividersBetween(rows),
      ),
    );
  }
}
