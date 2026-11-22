import 'package:path_provider/path_provider.dart';

import '../../shared/session/backend_scope.dart';
import '../../shared/settings/openai_key_store.dart';
import 'backend_launch.dart';

const OpenAiKeyStore _keyStore = OpenAiKeyStore(runCommand);

Future<void> relaunchBackendInPlace(BackendLink link) async {
  final openAiKey = await _keyStore.readKey();

  await link.disconnect();

  final dataDirectory = await getApplicationSupportDirectory();
  final launched = await launchBackend(
    dataDirectory: dataDirectory,
    openAiKey: openAiKey,
  );

  link.connect(launched.client, launched.running);
}
