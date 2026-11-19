import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/backend/backend_process.dart';
import 'package:leffic/shared/backend/free_port.dart';

import '../../support/property.dart';

const Duration _shortPatience = Duration(milliseconds: 300);
const Duration _longPatience = Duration(seconds: 5);

void main() {
  test('findFreeLoopbackPort property hands out bindable ports', () async {
    for (var run = 0; run < 10; run++) {
      final port = await findFreeLoopbackPort();
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );

      expect(port, inInclusiveRange(1024, 65535));

      await server.close();
    }
  });

  test('waitUntilListening property returns once the port opens', () async {
    final delays = <int>[];
    forAll((random) => integerBetween(random, 0, 200), delays.add, runs: 5);

    for (final delay in delays) {
      final port = await findFreeLoopbackPort();
      final opening = Future<ServerSocket>.delayed(
        Duration(milliseconds: delay),
        () => ServerSocket.bind(InternetAddress.loopbackIPv4, port),
      );

      await waitUntilListening(port, _longPatience);

      await (await opening).close();
    }
  });

  test('waitUntilListening property gives up on a silent port', () async {
    final port = await findFreeLoopbackPort();

    await expectLater(
      waitUntilListening(port, _shortPatience),
      throwsA(isA<BackendStartError>()),
    );
  });

  test('startBackend property runs the command in the data folder', () async {
    final directory = await Directory.systemTemp.createTemp('backend');
    final port = await findFreeLoopbackPort();
    final command = BackendCommand(
      executable: '/bin/sh',
      arguments: ['-c', 'pwd > started.txt; exec nc -l 127.0.0.1 $port'],
    );

    final backend = await startBackend(
      command: command,
      environment: {'DESKTOP_PORT': '$port'},
      dataDirectory: directory,
      port: port,
      patience: _longPatience,
    );
    final startedIn = await File('${directory.path}/started.txt')
        .readAsString();

    await backend.stop();

    expect(startedIn.trim(), endsWith(directory.path.split('/').last));
    await directory.delete(recursive: true);
  });

  test('stop property ends the backend process', () async {
    final directory = await Directory.systemTemp.createTemp('backend');
    final port = await findFreeLoopbackPort();
    final backend = await startBackend(
      command: BackendCommand(
        executable: '/usr/bin/nc',
        arguments: ['-lk', '127.0.0.1', '$port'],
      ),
      environment: const {},
      dataDirectory: directory,
      port: port,
      patience: _longPatience,
    );

    await backend.stop();

    expect(await backend.exitCode, isNot(0));
    await directory.delete(recursive: true);
  });
}
