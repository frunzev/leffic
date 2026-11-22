import 'package:leffic/shared/api/api_client.dart';

import '../support/backend_fakes.dart';

const Map<String, String> ratingScores = {
  'Again': '1',
  'Hard': '2',
  'Good': '3',
  'Easy': '4',
};

class UiWorld {
  final Map<String, ReplyToRequest> replies = {};
  final Map<String, int> intervalSeconds = {
    '1': 30,
    '2': 600,
    '3': 900,
    '4': 9000,
  };
  FakeBackend? _backend;

  FakeBackend backend() {
    return _backend ??= FakeBackend(replies);
  }

  ApiClient client() {
    return backend().client();
  }
}
