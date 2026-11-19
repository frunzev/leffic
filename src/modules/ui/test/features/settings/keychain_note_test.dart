import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/keychain_note.dart';
import 'package:leffic/features/settings/secure_note.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/hint_tip.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';

const double _sfProUnitsPerEm = 2048;
const double _sfProAscent = 1980;
const double _sfProDescent = 432;
const double _sfProXHeight = 1040;

void main() {
  testWidgets('KeychainNote property says where the key is kept', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);
    final cssMiddleDrop =
        (_sfProAscent - _sfProDescent - _sfProXHeight) /
        _sfProUnitsPerEm /
        2 *
        14;

    await tester.pumpWidget(
      hostedPlainly(const SizedBox(width: 526, child: KeychainNote())),
    );

    final note = tester.widget<SecureNote>(find.byType(SecureNote));
    final hintTip = tester.widget<HintTip>(find.byType(HintTip));
    final dropFinder = find.ancestor(
      of: find.byType(HintTip),
      matching: find.byType(Transform),
    );
    final drop = tester.widget<Transform>(dropFinder.first);

    expect(find.textContaining(keychainNoteText), findsOneWidget);
    expect(note.icon, DesignIcons.success);
    expect(note.iconColor, colors.success);
    expect(hintTip.text, keychainHintText);
    expect(hintTip.text, contains('Keychain'));
    expect(drop.transform.getTranslation().y, closeTo(cssMiddleDrop, 1e-9));
  });
}
