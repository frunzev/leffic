import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/toast.dart';
import 'package:leffic/shared/office/missing_libreoffice.dart';

import '../../support/property.dart';

void main() {
  test('isMissingLibreOffice property spots the backend refusal', () {
    forAll(
      (random) => (
        oneOf(random, ['', 'Conversion failed: ']),
        '/${wordOf(random)}/${tokenOf(random)}/soffice',
      ),
      (example) {
        final (prefix, binary) = example;
        final refusal = '${prefix}LibreOffice is not installed at $binary';

        expect(isMissingLibreOffice(refusal), isTrue);
      },
    );
  });

  test('isMissingLibreOffice property ignores every other failure', () {
    forAll((random) => 'Conversion failed: ${anyTextOf(random)}', (reason) {
      expect(isMissingLibreOffice(reason), isFalse);
    });
  });

  test('missingLibreOfficeMessage property points to Settings', () {
    expect(missingLibreOfficeMessage.tone, ToastTone.failure);
    expect(missingLibreOfficeMessage.title, 'LibreOffice is not installed');
    expect(
      missingLibreOfficeMessage.detail,
      'Download it in Settings to open Word, Excel and PowerPoint files.',
    );
  });
}
