import 'package:flutter/foundation.dart';

class DocumentPageReports {
  const DocumentPageReports({
    required this.openingPage,
    required this.onPageCountChanged,
    required this.onVisiblePageChanged,
  });

  final int openingPage;
  final ValueChanged<int> onPageCountChanged;
  final ValueChanged<int> onVisiblePageChanged;
}
