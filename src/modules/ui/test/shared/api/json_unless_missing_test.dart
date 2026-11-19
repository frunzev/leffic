import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/api_error.dart';
import 'package:leffic/shared/api/json_reading.dart';
import 'package:leffic/shared/api/json_unless_missing.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';

const String _countPath = '/count';

int _readCount(JsonObject json) => readWholeNumber(json, 'count');

void main() {
  test('readJsonUnlessMissing property reads every present reply', () async {
    for (final (scopeId, count) in examplesOf(
      (random) => (tokenOf(random), integerBetween(random, 0, 900)),
    )) {
      final backend = FakeBackend({
        _countPath: answerWith({'count': count}),
      });

      final readCount = await readJsonUnlessMissing(
        client: backend.client(),
        path: _countPath,
        query: {'scope_id': scopeId},
        whenMissing: -1,
        read: _readCount,
      );
      final request = backend.received.single;

      expect(readCount, count);
      expect(request.method, 'GET');
      expect(request.url.queryParameters, {'scope_id': scopeId});
    }
  });

  test('readJsonUnlessMissing property answers a missing reply', () async {
    for (final (scopeId, fallback) in examplesOf(
      (random) => (tokenOf(random), integerBetween(random, 0, 900)),
    )) {
      final backend = FakeBackend({_countPath: failWith(404, 'Missing')});

      final readCount = await readJsonUnlessMissing(
        client: backend.client(),
        path: _countPath,
        query: {'scope_id': scopeId},
        whenMissing: fallback,
        read: _readCount,
      );

      expect(readCount, fallback);
    }
  });

  test('readJsonUnlessMissing property raises every other failure', () async {
    for (final (status, detail) in examplesOf(
      (random) => (oneOf(random, [400, 401, 422, 500, 503]), wordOf(random)),
      runs: 10,
    )) {
      final backend = FakeBackend({_countPath: failWith(status, detail)});

      await expectLater(
        readJsonUnlessMissing(
          client: backend.client(),
          path: _countPath,
          query: {'scope_id': 'scope'},
          whenMissing: 0,
          read: _readCount,
        ),
        throwsA(
          isA<ApiError>()
              .having((failure) => failure.statusCode, 'statusCode', status)
              .having((failure) => failure.detail, 'detail', detail),
        ),
      );
    }
  });
}
