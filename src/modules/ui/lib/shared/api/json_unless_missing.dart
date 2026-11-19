import 'api_client.dart';
import 'api_error.dart';
import 'json_reading.dart';

typedef JsonReader<T> = T Function(JsonObject json);

const int _missingStatus = 404;

Future<T> readJsonUnlessMissing<T>({
  required ApiClient client,
  required String path,
  required QueryParameters query,
  required T whenMissing,
  required JsonReader<T> read,
}) async {
  final Object? reply;

  try {
    reply = await client.getJson(path, query);
  } on ApiError catch (failure) {
    if (failure.statusCode == _missingStatus) {
      return whenMissing;
    }

    rethrow;
  }

  return read(asObject(reply));
}
