import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void useTemporarySupportDirectory() {
  final directory = Directory.systemTemp.createTempSync('leffic-support');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    _pathProviderChannel,
    (call) async => directory.path,
  );
  addTearDown(() {
    messenger.setMockMethodCallHandler(_pathProviderChannel, null);
    directory.deleteSync(recursive: true);
  });
}
