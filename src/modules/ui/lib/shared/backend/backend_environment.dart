import '../settings/chat_engine_choice.dart';
import 'desktop_tools.dart';

const String _databaseUrl = 'sqlite:///content.db';
const String _brokerUrl = 'memory://';
const String _resultBackendUrl = 'db+sqlite:///generation-results.sqlite';
const String backendToolSearchPath =
    '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin';

class BackendSettings {
  const BackendSettings({
    required this.port,
    required this.parentProcessId,
    required this.secret,
    required this.openAiKey,
    required this.chatEngine,
    required this.tools,
  });

  final int port;
  final int parentProcessId;
  final String secret;
  final String? openAiKey;
  final ChatEngineChoice chatEngine;
  final DesktopTools? tools;
}

Map<String, String> backendEnvironment(BackendSettings settings) {
  final openAiKey = settings.openAiKey;
  final libreOfficeBinary = settings.tools?.libreOfficeBinary;
  final textRecognizerBinary = settings.tools?.textRecognizerBinary;

  return {
    'DESKTOP_PORT': '${settings.port}',
    'DESKTOP_PARENT_PROCESS_ID': '${settings.parentProcessId}',
    'JWT_SECRET_KEY': settings.secret,
    'CHAT_ENGINE': settings.chatEngine.setting,
    'DATABASE_URL': _databaseUrl,
    'CELERY_BROKER_URL': _brokerUrl,
    'CELERY_RESULT_BACKEND': _resultBackendUrl,
    'PATH': backendToolSearchPath,
    'LIBREOFFICE_BINARY': ?libreOfficeBinary,
    'TEXT_RECOGNIZER_BINARY': ?textRecognizerBinary,
    'OPENAI_API_KEY': ?openAiKey,
  };
}
