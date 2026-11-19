import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/api/json_reading.dart';

typedef ReplyToRequest = Future<http.Response> Function(http.Request request);

const String _fakeBaseUrl = 'http://127.0.0.1:4100';
const String _fakeToken = 'token';
const int _okStatus = 200;
const int _notFoundStatus = 404;
const String _notFoundBody = '{"detail":"Not Found"}';
const Map<String, String> _jsonHeaders = {'content-type': 'application/json'};

class FakeBackend {
  FakeBackend(this.replies);

  final Map<String, ReplyToRequest> replies;
  final List<http.Request> received = [];

  ApiClient client() {
    return ApiClient(
      baseUrl: _fakeBaseUrl,
      token: _fakeToken,
      transport: MockClient(_answer),
    );
  }

  List<http.Request> sentTo(String path) {
    final matching = <http.Request>[];

    for (final request in received) {
      if (request.url.path == path) {
        matching.add(request);
      }
    }

    return matching;
  }

  Future<http.Response> _answer(http.Request request) async {
    received.add(request);

    final reply = replies[request.url.path];

    if (reply == null) {
      return http.Response(_notFoundBody, _notFoundStatus);
    }

    return reply(request);
  }
}

http.Response jsonReply(Object? body) {
  return http.Response(jsonEncode(body), _okStatus, headers: _jsonHeaders);
}

ReplyToRequest answerWith(Object? body) {
  return (request) async => jsonReply(body);
}

ReplyToRequest failWith(int statusCode, String detail) {
  final failureBody = jsonEncode({'detail': detail});

  return (request) async =>
      http.Response(failureBody, statusCode, headers: _jsonHeaders);
}

JsonObject sentBody(http.Request request) {
  return asObject(jsonDecode(request.body));
}
