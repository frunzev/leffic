import 'dart:io';

import 'package:http/http.dart' as http;

import '../../shared/api/api_client.dart';
import '../../shared/backend/backend_environment.dart';
import '../../shared/backend/backend_process.dart';
import '../../shared/backend/desktop_tools.dart';
import '../../shared/backend/free_port.dart';
import '../../shared/backend/libreoffice_layout.dart';
import '../../shared/backend/local_token.dart';
import '../../shared/settings/app_preferences.dart';

const Duration _startPatience = Duration(seconds: 90);
const String _bundledBackend =
    'Resources/backend/leffic-backend/leffic-backend';
const String _bundledTextRecognizer = 'Resources/tools/leffic-text-recognizer';
const String _developmentPython = String.fromEnvironment(
  'LEFFIC_BACKEND_PYTHON',
);
const String _developmentScript = String.fromEnvironment(
  'LEFFIC_BACKEND_SCRIPT',
);

class LaunchedBackend {
  const LaunchedBackend({required this.client, required this.running});

  final ApiClient client;
  final RunningBackend running;
}

BackendCommand backendCommandFor({
  required String developmentPython,
  required String developmentScript,
  required String appExecutable,
}) {
  if (developmentPython.isNotEmpty) {
    return BackendCommand(
      executable: developmentPython,
      arguments: [developmentScript],
    );
  }

  final contents = File(appExecutable).parent.parent.path;

  return BackendCommand(
    executable: '$contents/$_bundledBackend',
    arguments: [],
  );
}

DesktopTools? desktopToolsFor({
  required String developmentPython,
  required String appExecutable,
  required String dataDirectory,
}) {
  if (developmentPython.isNotEmpty) {
    return null;
  }

  final contents = File(appExecutable).parent.parent.path;

  return DesktopTools(
    libreOfficeBinary: LibreOfficeLayout(dataDirectory).binary,
    textRecognizerBinary: '$contents/$_bundledTextRecognizer',
  );
}

String loopbackAddress(int port) => 'http://127.0.0.1:$port';

Future<LaunchedBackend> launchBackend({
  required Directory dataDirectory,
  required String? openAiKey,
}) async {
  final preferences = await loadPreferences(dataDirectory);
  final port = await findFreeLoopbackPort();
  final secret = newLaunchSecret();
  final settings = BackendSettings(
    port: port,
    parentProcessId: pid,
    secret: secret,
    openAiKey: openAiKey,
    chatEngine: preferences.chatEngine,
    tools: desktopToolsFor(
      developmentPython: _developmentPython,
      appExecutable: Platform.resolvedExecutable,
      dataDirectory: dataDirectory.path,
    ),
  );
  final command = backendCommandFor(
    developmentPython: _developmentPython,
    developmentScript: _developmentScript,
    appExecutable: Platform.resolvedExecutable,
  );
  final running = await startBackend(
    command: command,
    environment: backendEnvironment(settings),
    dataDirectory: dataDirectory,
    port: port,
    patience: _startPatience,
  );
  final client = ApiClient(
    baseUrl: loopbackAddress(port),
    token: signLocalToken(secret: secret, userId: localUserId),
    transport: http.Client(),
  );

  return LaunchedBackend(client: client, running: running);
}
