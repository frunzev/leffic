import 'package:flutter/widgets.dart';

import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/focus_outline.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/pressable.dart';
import '../../shared/navigation/home_navigation.dart';
import '../../shared/navigation/routes.dart';
import 'folder_models.dart';

const double _titleLetterSpacingInEm = -0.01;
const double _crumbOutlineRadius = 0;
const Widget _crumbChevron = DesignIcon(
  DesignIcons.chevronRight,
  size: IconSizes.small,
);

class FolderHeader extends StatelessWidget {
  const FolderHeader({
    required this.ancestors,
    required this.folderName,
    required this.actions,
    super.key,
  });

  final List<FolderAncestor> ancestors;
  final String folderName;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        textStyleForSize(
          TextSizes.doubleExtraLarge,
          addedLetterSpacingInEm: _titleLetterSpacingInEm,
        ).copyWith(
          color: DesignColors.of(context).ink,
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step4,
      children: [
        if (ancestors.isNotEmpty)
          FolderCrumbs(ancestors: ancestors, folderName: folderName),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Spacing.step4,
          runSpacing: Spacing.step4,
          children: [
            Text(folderName, style: titleStyle),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.step2,
              runSpacing: Spacing.step2,
              children: actions,
            ),
          ],
        ),
      ],
    );
  }
}

class FolderCrumbs extends StatelessWidget {
  const FolderCrumbs({
    required this.ancestors,
    required this.folderName,
    super.key,
  });

  final List<FolderAncestor> ancestors;
  final String folderName;

  void _openAncestor(BuildContext context, FolderAncestor ancestor) {
    final arguments = UnitArguments(id: ancestor.id, name: ancestor.name);

    Navigator.of(context).pushNamed(Routes.folder, arguments: arguments);
  }

  List<Widget> _crumbTrail(BuildContext context) {
    final rootFolder = ancestors.first;
    final trail = <Widget>[
      CrumbLink(
        label: rootFolder.name,
        onPressed: () => openHomeFolder(context),
      ),
      _crumbChevron,
    ];

    for (final ancestor in ancestors.skip(1)) {
      trail.add(
        CrumbLink(
          label: ancestor.name,
          onPressed: () => _openAncestor(context, ancestor),
        ),
      );
      trail.add(_crumbChevron);
    }

    return trail;
  }

  @override
  Widget build(BuildContext context) {
    final crumbStyle = textStyleForSize(TextSizes.small)
        .copyWith(color: DesignColors.of(context).inkTertiary);

    return DefaultTextStyle.merge(
      style: crumbStyle,
      child: Wrap(
        spacing: Spacing.step2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [..._crumbTrail(context), Text(folderName)],
      ),
    );
  }
}

class CrumbLink extends StatelessWidget {
  const CrumbLink({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  Widget _buildFace(BuildContext context, InteractionState state) {
    final colors = DesignColors.of(context);
    final style = state.isHovered
        ? TextStyle(color: colors.ink, decoration: TextDecoration.underline)
        : TextStyle(color: colors.inkTertiary);

    return FocusOutline(
      state: state,
      borderRadius: _crumbOutlineRadius,
      child: Text(label, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(onPressed: onPressed, builder: _buildFace);
  }
}

class NewFolderButton extends StatelessWidget {
  const NewFolderButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DesignButton(
      label: 'New folder',
      icon: DesignIcons.newFolder,
      size: ButtonSize.small,
      onPressed: onPressed,
    );
  }
}

class ImportButton extends StatelessWidget {
  const ImportButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DesignButton(
      label: 'Import',
      icon: DesignIcons.aiImport,
      size: ButtonSize.small,
      onPressed: onPressed,
    );
  }
}
