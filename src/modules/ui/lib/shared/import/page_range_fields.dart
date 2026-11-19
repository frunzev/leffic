import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_field.dart';
import '../design/design_metrics.dart';
import '../design/design_text_field.dart';
import '../design/design_typography.dart';

const double _pageFieldWidth = 88;
const String _pagesLabel = 'Pages';
const String _rangeWord = 'to';
const String _firstPagePlaceholder = '1';
const String _lastPagePlaceholder = 'last';
const String _pagesHint =
    'Leave the first empty to start at page 1, the last to read to the end, '
    'both to read the whole document.';

class PageRangeFields extends StatelessWidget {
  const PageRangeFields({
    required this.firstPage,
    required this.lastPage,
    required this.onChanged,
    super.key,
  });

  final TextEditingController firstPage;
  final TextEditingController lastPage;
  final ValueChanged<String> onChanged;

  Widget _pageField(TextEditingController page, String placeholder) {
    return SizedBox(
      width: _pageFieldWidth,
      child: DesignTextField(
        controller: page,
        placeholder: placeholder,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return DesignField(
      label: _pagesLabel,
      hint: _pagesHint,
      input: Row(
        spacing: Spacing.step2,
        children: [
          _pageField(firstPage, _firstPagePlaceholder),
          Text(
            _rangeWord,
            style: textStyleForSize(TextSizes.small)
                .copyWith(color: colors.inkSecondary),
          ),
          _pageField(lastPage, _lastPagePlaceholder),
        ],
      ),
    );
  }
}
