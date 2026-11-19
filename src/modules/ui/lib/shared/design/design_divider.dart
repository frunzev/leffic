import 'package:flutter/material.dart';

import 'design_colors.dart';

const double _dividerThickness = 1;

class DesignDivider extends StatelessWidget {
  const DesignDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _dividerThickness,
      width: double.infinity,
      child: ColoredBox(color: DesignColors.of(context).line),
    );
  }
}
