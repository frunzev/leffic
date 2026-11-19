import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/libreoffice_release.dart';

import '../../support/property.dart';

const int _bytesInMegabyte = 1000000;

void main() {
  test('downloadSizeLabel property rounds to the nearest megabyte', () {
    forAll((random) => integerBetween(random, 0, 1 << 31), (bytes) {
      final label = downloadSizeLabel(bytes);
      final megabytes = int.parse(label.replaceAll(' MB', ''));

      expect(label, endsWith(' MB'));
      expect(
        (megabytes * _bytesInMegabyte - bytes).abs(),
        lessThanOrEqualTo(_bytesInMegabyte ~/ 2),
      );
    });
  });

  test('libreOfficeRelease property pins the official Apple silicon image', () {
    final address = Uri.parse(libreOfficeRelease.address);

    expect(address.scheme, 'https');
    expect(address.host, 'download.documentfoundation.org');
    expect(address.path, endsWith('/LibreOffice_26.8.2_MacOS_aarch64.dmg'));
    expect(
      libreOfficeRelease.sha256,
      '9f24fe83ab1ed5c95eb3df580119f32932f713e577feeac02bf619fb00749b55',
    );
    expect(libreOfficeRelease.bytes, 299236406);
  });
}
