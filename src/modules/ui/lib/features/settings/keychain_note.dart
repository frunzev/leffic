import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/hint_tip.dart';
import '../../shared/design/icons/design_icons.dart';
import 'secure_note.dart';

const String keychainNoteText =
    'Your key is kept in the macOS Keychain on this Mac.';
const double _systemFontAscent = 1980 / 2048;
const double _systemFontDescent = 432 / 2048;
const double _systemFontXHeight = 1040 / 2048;
const double _cssMiddleDrop =
    (_systemFontAscent - _systemFontDescent - _systemFontXHeight) /
    2 *
    TextSizes.small;
const String keychainHintText =
    'Leffic reads the key from the Keychain when it starts and hands it '
    'only to its own backend on this Mac, which sends it to OpenAI.';

class KeychainNote extends StatelessWidget {
  const KeychainNote({super.key});

  @override
  Widget build(BuildContext context) {
    return SecureNote(
      icon: DesignIcons.success,
      iconColor: DesignColors.of(context).success,
      children: [
        Text.rich(
          TextSpan(
            text: '$keychainNoteText ',
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  offset: const Offset(0, _cssMiddleDrop),
                  child: const Padding(
                    padding: EdgeInsets.only(left: Spacing.step1),
                    child: HintTip(
                      text: keychainHintText,
                      semanticLabel: 'Where the key is kept',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
