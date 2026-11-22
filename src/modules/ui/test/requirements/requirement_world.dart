import 'package:flutter/widgets.dart';
import 'package:leffic/features/files/file_models.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/session/backend_scope.dart';

import '../features/settings/settings_fakes.dart';
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
  RecordingRelauncher relauncher = RecordingRelauncher();
  final List<RouteSettings> openedRoutes = [];
  final Map<String, int> optionIds = {};
  final Map<String, StoredFileDetails> fileDetails = {};
  RecordingKeychain keychain = RecordingKeychain(0);
  String? claudeCodeLocation = '/Users/someone/.local/bin/claude';
  final BackendLink link = connectedLink();
  FakeBackend? _backend;

  FakeBackend backend() {
    return _backend ??= FakeBackend(replies);
  }

  ApiClient client() {
    return backend().client();
  }
}
