import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/backend/backend_process.dart';
import 'package:leffic/shared/backend/free_port.dart';
import 'package:leffic/shared/session/backend_scope.dart';

import '../../support/property.dart';

class ClientReader extends StatelessWidget {
  const ClientReader({required this.builds, super.key});

  final List<String> builds;

  @override
  Widget build(BuildContext context) {
    builds.add(BackendScope.clientOf(context).baseUrl);

    return const SizedBox();
  }
}

ApiClient _clientAt(String baseUrl) {
  return ApiClient(
    baseUrl: baseUrl,
    token: 't',
    transport: MockClient((request) async => http.Response('', 200)),
  );
}

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

  testWidgets('clientOf property never rebuilds a reader on link changes', (
    tester,
  ) async {
    final toggleCounts = <int>[];
    forAll((random) => integerBetween(random, 1, 6), toggleCounts.add, runs: 5);

    for (final toggles in toggleCounts) {
      final link = BackendLink()..value = _clientAt('http://first');
      final builds = <String>[];

      await tester.pumpWidget(
        BackendScope(
          link: link,
          child: ClientReader(key: UniqueKey(), builds: builds),
        ),
      );

      for (var toggle = 0; toggle < toggles; toggle++) {
        link.value = toggle.isEven ? null : _clientAt('http://next');
        await tester.pump();
      }

      expect(builds, ['http://first']);
      expect(tester.takeException(), isNull);
    }
  });
}
