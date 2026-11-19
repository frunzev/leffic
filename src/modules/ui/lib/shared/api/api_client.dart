import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_error.dart';
import 'json_reading.dart';

typedef QueryParameters = Map<String, String>;

const String _jsonContentType = 'application/json';
const int _firstFailureStatus = 400;
const List<String> _messageKeys = ['detail', 'msg'];

class UploadedFile {
  const UploadedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class ApiClient {
  const ApiClient({
    required this.baseUrl,
    required this.token,
    required this.transport,
  });

  final String baseUrl;
  final String token;
  final http.Client transport;

  Uri uriFor(String path, [QueryParameters? query]) {
    final address = Uri.parse('$baseUrl$path');

    if (query == null) {
      return address;
    }

    return address.replace(queryParameters: query);
  }

  Future<Object?> getJson(String path, [QueryParameters? query]) async {
    final reply = await transport.get(uriFor(path, query), headers: _headers());

    return _decoded(reply, path);
  }

  Future<Object?> sendJson(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    final request = http.Request(method, uriFor(path))
      ..headers.addAll(_headers())
      ..headers['Content-Type'] = _jsonContentType
      ..body = jsonEncode(body);
    final reply = await http.Response.fromStream(await transport.send(request));

    return _decoded(reply, path);
  }

  Future<Object?> delete(String path, [QueryParameters? query]) async {
    final reply = await transport.delete(
      uriFor(path, query),
      headers: _headers(),
    );

    return _decoded(reply, path);
  }

  Future<Uint8List> getBytes(String path, [QueryParameters? query]) async {
    final reply = await transport.get(uriFor(path, query), headers: _headers());

    _refuseFailure(reply, path);

    return reply.bodyBytes;
  }

  Future<Object?> uploadFiles(
    String path,
    Map<String, String> fields,
    List<UploadedFile> files,
  ) async {
    final request = http.MultipartRequest('POST', uriFor(path))
      ..headers.addAll(_headers())
      ..fields.addAll(fields);

    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes('files', file.bytes, filename: file.name),
      );
    }

    final reply = await http.Response.fromStream(await transport.send(request));

    return _decoded(reply, path);
  }

  Map<String, String> _headers() => {'Authorization': 'Bearer $token'};

  Object? _decoded(http.Response reply, String path) {
    _refuseFailure(reply, path);

    if (reply.body.isEmpty) {
      return null;
    }

    return jsonDecode(reply.body);
  }

  void _refuseFailure(http.Response reply, String path) {
    if (reply.statusCode < _firstFailureStatus) {
      return;
    }

    throw ApiError(
      statusCode: reply.statusCode,
      path: path,
      detail: _failureDetail(reply),
    );
  }

  String _failureDetail(http.Response reply) {
    try {
      final failure = asObject(jsonDecode(reply.body));

      for (final key in _messageKeys) {
        final message = failure[key];

        if (message != null) {
          return '$message';
        }
      }

      return '${reply.reasonPhrase}';
    } on FormatException {
      return reply.reasonPhrase ?? 'Request failed (${reply.statusCode})';
    }
  }
}
