import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/icons/design_icons.dart';

String bookmarkLabel({required int pageInView, required int? bookmarkedPage}) {
  if (pageInView == bookmarkedPage) {
    return 'Remove the bookmark on page $pageInView';
  }

  return 'Bookmark page $pageInView';
}

class FileBookmarkButton extends StatelessWidget {
  const FileBookmarkButton({
    required this.pageInView,
    required this.bookmarkedPage,
    required this.onRemember,
    required this.onForget,
    super.key,
  });

  final int pageInView;
  final int? bookmarkedPage;
  final ValueChanged<int> onRemember;
  final VoidCallback onForget;

  bool get _isPageInViewBookmarked => pageInView == bookmarkedPage;

  void _toggleBookmark() {
    if (_isPageInViewBookmarked) {
      onForget();
      return;
    }

    onRemember(pageInView);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkedColor = DesignColors.of(context).brand;

    return DesignIconButton(
      icon: DesignIcons.bookmark,
      semanticLabel: bookmarkLabel(
        pageInView: pageInView,
        bookmarkedPage: bookmarkedPage,
      ),
      variant: ButtonVariant.quiet,
      iconColor: _isPageInViewBookmarked ? bookmarkedColor : null,
      onPressed: _toggleBookmark,
    );
  }
}
