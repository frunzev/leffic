import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/backend/libreoffice_layout.dart';

import '../../support/property.dart';

String _directoryOf(String path) => path.substring(0, path.lastIndexOf('/'));

void main() {
  test('LibreOfficeLayout property keeps every path in the data folder', () {
    forAll((random) => '/${wordOf(random)}/${tokenOf(random)}', (directory) {
      final layout = LibreOfficeLayout(directory);
      final paths = [
        layout.application,
        layout.stagedApplication,
        layout.binary,
        layout.image,
      ];

      for (final path in paths) {
        expect(path, startsWith('$directory/'));
      }

      expect(paths.toSet(), hasLength(paths.length));
      expect(_directoryOf(layout.application), directory);
      expect(_directoryOf(layout.stagedApplication), directory);
      expect(_directoryOf(layout.image), directory);
    });
  });

  test('LibreOfficeLayout property finds soffice inside the app', () {
    forAll((random) => '/${tokenOf(random)}', (directory) {
      final layout = LibreOfficeLayout(directory);

      expect(layout.application, endsWith('/LibreOffice.app'));
      expect(layout.binary, '${layout.application}/Contents/MacOS/soffice');
      expect(layout.image, endsWith('.dmg'));
      expect(
        layout.stagedApplication,
        isNot(startsWith('${layout.application}/')),
      );
    });
  });
}
