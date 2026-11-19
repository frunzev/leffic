import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/backend/backend_environment.dart';
import 'package:leffic/shared/backend/desktop_tools.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';

import '../../support/property.dart';

void main() {
  test('backendEnvironment property carries every launch setting', () {
    forAll(
      (random) => BackendSettings(
        port: integerBetween(random, 1024, 65535),
        secret: tokenOf(random),
        openAiKey: oneOf(random, [null, tokenOf(random)]),
        chatEngine: oneOf(random, ChatEngineChoice.values),
        tools: oneOf(random, [
          null,
          DesktopTools(
            libreOfficeBinary: '/${tokenOf(random)}/soffice',
            textRecognizerBinary: '/${tokenOf(random)}/recognizer',
          ),
        ]),
      ),
      (settings) {
        final environment = backendEnvironment(settings);

        expect(environment['DESKTOP_PORT'], '${settings.port}');
        expect(environment['JWT_SECRET_KEY'], settings.secret);
        expect(environment['OPENAI_API_KEY'], settings.openAiKey);
        expect(
          environment.containsKey('OPENAI_API_KEY'),
          settings.openAiKey != null,
        );
        expect(environment['CHAT_ENGINE'], settings.chatEngine.setting);
        expect(environment['DATABASE_URL'], startsWith('sqlite:///'));
        expect(environment['CELERY_BROKER_URL'], 'memory://');
        expect(environment['CELERY_RESULT_BACKEND'], startsWith('db+sqlite'));
        expect(
          environment['LIBREOFFICE_BINARY'],
          settings.tools?.libreOfficeBinary,
        );
        expect(
          environment['TEXT_RECOGNIZER_BINARY'],
          settings.tools?.textRecognizerBinary,
        );
        expect(
          environment['PATH']!.split(':'),
          containsAll(['/opt/homebrew/bin', '/usr/local/bin', '/usr/bin']),
        );
        expect(environment['PATH'], backendToolSearchPath);
      },
    );
  });
}
