import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';
import 'icons/design_icon.dart';
import 'icons/design_icons.dart';

const double _errorIconSize = 16;
const double _errorIconDrop = 4;

class DesignField extends StatelessWidget {
  const DesignField({
    required this.label,
    required this.input,
    this.hint,
    this.error,
    super.key,
  });

  final String label;
  final Widget input;
  final String? hint;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final hintText = hint;
    final errorText = error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step2,
      children: [
        Text(
          label,
          style: textStyleForSize(TextSizes.small)
              .copyWith(color: colors.ink, fontWeight: FontWeight.w500),
        ),
        input,
        if (hintText != null)
          Text(
            hintText,
            style: textStyleForSize(TextSizes.extraSmall)
                .copyWith(color: colors.inkTertiary),
          ),
        if (errorText != null) FieldError(message: errorText),
      ],
    );
  }
}

class FieldError extends StatelessWidget {
  const FieldError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final danger = DesignColors.of(context).danger;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.step1,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _errorIconDrop),
          child: DesignIcon(
            DesignIcons.failure,
            size: _errorIconSize,
            color: danger,
          ),
        ),
        Expanded(
          child: Text(
            message,
            style: textStyleForSize(TextSizes.small).copyWith(color: danger),
          ),
        ),
      ],
    );
  }
}
