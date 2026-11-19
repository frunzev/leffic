import 'dart:io';

import 'package:flutter/services.dart';

const String _systemFontFile = '/System/Library/Fonts/SFNS.ttf';
const List<String> _systemFontFamilies = [
  '.AppleSystemUIFont',
  'CupertinoSystemText',
  'CupertinoSystemDisplay',
  'Roboto',
  'FlutterTest',
];

Future<void> loadSystemFonts() async {
  final fontBytes = File(_systemFontFile).readAsBytesSync();

  for (final family in _systemFontFamilies) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(fontBytes)));

    await loader.load();
  }
}
