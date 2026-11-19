import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/session/backend_scope.dart';

typedef ShotReply = Future<http.Response> Function(http.Request request);

const Map<String, String> _jsonHeaders = {'content-type': 'application/json'};
const String _shotBaseUrl = 'http://127.0.0.1:4100';
const String _shotToken = 'token';
const int _okStatus = 200;
const int _notFoundStatus = 404;
const String _notFoundBody = '{"detail":"Not Found"}';

http.Response shotJsonReply(Object? body) {
  return http.Response(jsonEncode(body), _okStatus, headers: _jsonHeaders);
}

http.Response shotNotFoundReply() {
  return http.Response(_notFoundBody, _notFoundStatus);
}

Future<http.Response> shotNeverReply(http.Request request) {
  return Completer<http.Response>().future;
}

ApiClient shotApiClient(ShotReply reply) {
  return ApiClient(
    baseUrl: _shotBaseUrl,
    token: _shotToken,
    transport: MockClient(reply),
  );
}

BackendLink shotBackendLink(ShotReply reply) {
  return BackendLink()..value = shotApiClient(reply);
}
