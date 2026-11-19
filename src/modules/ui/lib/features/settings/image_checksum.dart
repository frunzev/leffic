import 'dart:io';

import 'package:crypto/crypto.dart';

import 'libreoffice_setup_error.dart';

const String _checksumMismatch =
    'The download does not match the official LibreOffice checksum';

Future<void> refuseUnlessSha256Matches({
  required File file,
  required String expectedSha256,
}) async {
  final digest = await sha256.bind(file.openRead()).first;

  if ('$digest' != expectedSha256) {
    throw const LibreOfficeSetupError(_checksumMismatch);
  }
}
