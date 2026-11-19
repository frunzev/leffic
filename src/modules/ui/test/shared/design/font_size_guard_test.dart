import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _libraryFolder = 'lib';
const String _typeModule = 'lib/shared/design/design_typography.dart';
const String _fontSizeArgument = 'fontSize:';
const String _dartExtension = '.dart';

List<String> _filesSettingAFontSize() {
  final offendingFiles = <String>[];
  final entries = Directory(_libraryFolder).listSync(recursive: true);

  for (final entry in entries) {
    final isDartFile = entry is File && entry.path.endsWith(_dartExtension);

    if (!isDartFile || entry.path == _typeModule) {
      continue;
    }

    if (entry.readAsStringSync().contains(_fontSizeArgument)) {
      offendingFiles.add(entry.path);
    }
  }

  return offendingFiles;
}

void main() {
  test('textStyleForSize property is the only place setting a font size', () {
    expect(File(_typeModule).existsSync(), isTrue);
    expect(_filesSettingAFontSize(), isEmpty);
  });
}
