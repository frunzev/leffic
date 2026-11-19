import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/property.dart';

const String _baseUrl = 'http://127.0.0.1:4100';

ApiClient _clientAnswering(
  List<http.Request> received,
  int status,
  String body,
) {
  final transport = MockClient((request) async {
    received.add(request);

    return http.Response(body, status);
  });

  return ApiClient(baseUrl: _baseUrl, token: 'signed', transport: transport);
}

void main() {
  _failureDetailProperties();

  test('getJson property sends the token and decodes the reply', () async {
    final examples = <(String, String)>[];
    forAll((random) => (wordOf(random), wordOf(random)), examples.add);

    for (final (path, value) in examples) {
      final received = <http.Request>[];
      final client = _clientAnswering(received, 200, jsonEncode({'v': value}));

      final reply = await client.getJson('/$path', {'q': value});

      expect(reply, {'v': value});
      expect(received.single.headers['Authorization'], 'Bearer signed');
      expect(received.single.url.path, '/$path');
      expect(received.single.url.queryParameters['q'], value);
    }
  });

  test('getJson property raises ApiError carrying the status', () async {
    final statuses = <int>[];
    forAll((random) => integerBetween(random, 400, 599), statuses.add);

    for (final status in statuses) {
      final client = _clientAnswering([], status, '{"detail":"refused"}');

      await expectLater(
        client.getJson('/thing'),
        throwsA(
          isA<ApiError>()
              .having((error) => error.statusCode, 'status', status)
              .having((error) => error.detail, 'detail', 'refused'),
        ),
      );
    }
  });

  test('sendJson property encodes the body with the chosen method', () async {
    final examples = <(String, String)>[];
    forAll(
      (random) => (oneOf(random, ['POST', 'PATCH', 'PUT']), wordOf(random)),
      examples.add,
      runs: 20,
    );

    for (final (method, value) in examples) {
      final received = <http.Request>[];
      final client = _clientAnswering(received, 200, '{}');

      await client.sendJson(method, '/save', {'name': value});

      expect(received.single.method, method);
      expect(jsonDecode(received.single.body), {'name': value});
      expect(received.single.headers['Content-Type'], contains('json'));
    }
  });

  test('delete property sends a DELETE with the query', () async {
    final values = <String>[];
    forAll(wordOf, values.add, runs: 20);

    for (final value in values) {
      final received = <http.Request>[];
      final client = _clientAnswering(received, 200, '{}');

      await client.delete('/remove', {'id': value});

      expect(received.single.method, 'DELETE');
      expect(received.single.url.queryParameters['id'], value);
    }
  });

  test('getBytes property hands back the exact reply bytes', () async {
    final payloads = <String>[];
    forAll(tokenOf, payloads.add, runs: 20);

    for (final payload in payloads) {
      final client = _clientAnswering([], 200, payload);

      final bytes = await client.getBytes('/file', {'id': '1'});

      expect(utf8.decode(bytes), payload);
    }
  });

  test('uriFor property keeps the base and appends path and query', () {
    final client = ApiClient(
      baseUrl: _baseUrl,
      token: 't',
      transport: MockClient((request) async => http.Response('', 200)),
    );

    forAll((random) => (wordOf(random), wordOf(random)), (example) {
      final (path, value) = example;
      final uri = client.uriFor('/$path', {'k': value});

      expect(uri.toString(), startsWith('$_baseUrl/$path'));
      expect(uri.queryParameters['k'], value);
    });
  });
}

void _failureDetailProperties() {
  test(
    'getJson property reports a msg field when there is no detail',
    () async {
      final messages = <String>[];
      forAll(wordOf, messages.add, runs: 10);

      for (final message in messages) {
        final client = _clientAnswering([], 400, '{"msg":"$message"}');

        await expectLater(
          client.getJson('/thing'),
          throwsA(isA<ApiError>().having((e) => e.detail, 'detail', message)),
        );
      }
    },
  );
}
