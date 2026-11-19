import 'package:flutter/material.dart';

import '../design/design_metrics.dart';
import '../design/segmented_control.dart';
import 'import_source.dart';

const double _pastedTextGap = 0;

String _kindLabelOf(ImportSourceKind kind) => kind.label;

double _panelGapFor(ImportSourceKind kind) {
  if (kind == ImportSourceKind.text) {
    return _pastedTextGap;
  }

  return Spacing.step4;
}

class SourceStep extends StatelessWidget {
  const SourceStep({
    required this.kind,
    required this.onKindSelected,
    required this.panel,
    super.key,
  });

  final ImportSourceKind kind;
  final ValueChanged<ImportSourceKind> onKindSelected;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedControl<ImportSourceKind>(
          choices: ImportSourceKind.values,
          labelOf: _kindLabelOf,
          selected: kind,
          onSelected: onKindSelected,
          size: SegmentedSize.large,
        ),
        SizedBox(height: _panelGapFor(kind)),
        panel,
      ],
    );
  }
}
