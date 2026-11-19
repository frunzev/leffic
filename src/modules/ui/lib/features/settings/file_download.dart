import 'dart:io';

import 'package:http/http.dart' as http;

import 'libreoffice_setup_error.dart';

typedef ReceivedBytesListener = void Function(int receivedBytes);

const String _downloadMethod = 'GET';

Future<void> downloadToFile({
  required http.Client client,
  required Uri address,
  required File destination,
  required ReceivedBytesListener onReceived,
}) async {
  final request = http.Request(_downloadMethod, address);
  final response = await client.send(request);

  if (response.statusCode != HttpStatus.ok) {
    throw LibreOfficeSetupError(
      'The download failed with status ${response.statusCode}',
    );
  }

  final sink = destination.openWrite();
  var receivedBytes = 0;

  try {
    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      onReceived(receivedBytes);
    }
  } finally {
    await sink.close();
  }
}
