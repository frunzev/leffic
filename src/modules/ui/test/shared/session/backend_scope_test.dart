import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/backend/backend_process.dart';
import 'package:leffic/shared/backend/free_port.dart';
import 'package:leffic/shared/session/backend_scope.dart';

void main() {
  test('connect property publishes the client until disconnect', () async {
    final directory = await Directory.systemTemp.createTemp('link');
    final port = await findFreeLoopbackPort();
    final running = await startBackend(
      command: BackendCommand(
        executable: '/usr/bin/nc',
        arguments: ['-lk', '127.0.0.1', '$port'],
      ),
      environment: const {},
      dataDirectory: directory,
      port: port,
      patience: const Duration(seconds: 5),
    );
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:$port',
      token: 't',
      transport: MockClient((request) async => http.Response('', 200)),
    );
    final link = BackendLink()..connect(client, running);

    expect(link.value, same(client));

    await link.disconnect();

    expect(link.value, isNull);
    expect(await running.exitCode, isNot(0));
    await directory.delete(recursive: true);
  });

  test('disconnect property is safe without a running backend', () async {
    final link = BackendLink();

    await link.disconnect();

    expect(link.value, isNull);
  });
}
