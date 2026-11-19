import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';

const int firstPage = 1;

class PagePosition extends StatelessWidget {
  const PagePosition({required this.page, required this.pageCount, super.key});

  final int page;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Page $page of $pageCount',
      maxLines: 1,
      softWrap: false,
      style: textStyleForSize(TextSizes.small).copyWith(
        color: DesignColors.of(context).inkSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
