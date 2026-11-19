import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../design/button_look.dart';
import '../design/design_button.dart';
import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';
import '../design/icons/design_icon.dart';
import '../design/icons/design_icons.dart';
import '../design/inset_block.dart';

const int _bytesPerKilobyte = 1000;
const int _bytesPerMegabyte = 1000000;
const int _megabyteDecimals = 1;

String describeFileSize(int byteCount) {
  if (byteCount < _bytesPerKilobyte) {
    return '$byteCount B';
  }

  if (byteCount < _bytesPerMegabyte) {
    final kilobytes = byteCount ~/ _bytesPerKilobyte;

    return '$kilobytes KB';
  }

  final megabytes = byteCount / _bytesPerMegabyte;

  return '${megabytes.toStringAsFixed(_megabyteDecimals)} MB';
}

class ChosenFile extends StatelessWidget {
  const ChosenFile({required this.file, required this.onRemove, super.key});

  final UploadedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return InsetBlock(
      child: Row(
        spacing: Spacing.step3,
        children: [
          DesignIcon(
            DesignIcons.file,
            size: IconSizes.regular,
            color: colors.inkTertiary,
          ),
          Expanded(
            child: Text(
              file.name,
              style: textStyleForSize(TextSizes.small)
                  .copyWith(color: colors.ink),
            ),
          ),
          Text(
            describeFileSize(file.bytes.length),
            style: textStyleForSize(TextSizes.extraSmall)
                .copyWith(color: colors.inkTertiary),
          ),
          DesignIconButton(
            icon: DesignIcons.closePlain,
            semanticLabel: 'Remove ${file.name}',
            variant: ButtonVariant.quiet,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
