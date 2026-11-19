import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/startup/backend_launch.dart';

import '../../support/property.dart';

void main() {
  test('backendCommandFor property runs the script in development', () {
    forAll((random) => (wordOf(random), wordOf(random)), (example) {
      final (python, script) = example;
      final command = backendCommandFor(
        developmentPython: '/venv/$python',
        developmentScript: '/repo/$script.py',
        appExecutable: '/Applications/Leffic.app/Contents/MacOS/leffic',
      );

      expect(command.executable, '/venv/$python');
      expect(command.arguments, ['/repo/$script.py']);
    });
  });

  test('backendCommandFor property uses the bundled backend otherwise', () {
    forAll(wordOf, (appName) {
      final command = backendCommandFor(
        developmentPython: '',
        developmentScript: '',
        appExecutable: '/Applications/$appName.app/Contents/MacOS/leffic',
      );

      expect(
        command.executable,
        '/Applications/$appName.app/Contents/Resources/backend/'
        'leffic-backend/leffic-backend',
      );
      expect(command.arguments, isEmpty);
    });
  });

  test('loopbackAddress property always targets this machine', () {
    forAll((random) => integerBetween(random, 1024, 65535), (port) {
      final address = Uri.parse(loopbackAddress(port));

      expect(address.host, '127.0.0.1');
      expect(address.port, port);
      expect(address.scheme, 'http');
    });
  });

  test('desktopToolsFor property finds each tool where the app keeps it', () {
    forAll((random) => (wordOf(random), '/Users/${wordOf(random)}/data'), (
      example,
    ) {
      final (appName, dataDirectory) = example;
      final tools = desktopToolsFor(
        developmentPython: '',
        appExecutable: '/Applications/$appName.app/Contents/MacOS/leffic',
        dataDirectory: dataDirectory,
      );
      final resources = '/Applications/$appName.app/Contents/Resources';

      expect(
        tools?.libreOfficeBinary,
        '$dataDirectory/LibreOffice.app/Contents/MacOS/soffice',
      );
      expect(
        tools?.textRecognizerBinary,
        '$resources/tools/leffic-text-recognizer',
      );
    });
  });

  test('desktopToolsFor property leaves development to the PATH', () {
    forAll(wordOf, (python) {
      final tools = desktopToolsFor(
        developmentPython: '/venv/$python',
        appExecutable: '/Applications/Leffic.app/Contents/MacOS/leffic',
        dataDirectory: '/Users/someone/data',
      );

      expect(tools, isNull);
    });
  });
}
