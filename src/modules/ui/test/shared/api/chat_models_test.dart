import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/chat_models.dart';

import '../../support/property.dart';
import 'chat_fakes.dart';

void main() {
  test('ChatMessage.toJson property sends the role and the content', () {
    forAll(generatedMessage, (message) {
      expect(message.toJson(), {
        'role': message.role.wireName,
        'content': message.content,
      });
    });
  });

  test('ChatRole property names every role as the backend does', () {
    forAll((random) => oneOf(random, ChatRole.values), (role) {
      expect(['user', 'assistant'], contains(role.wireName));
      expect(role.wireName, role.name);
    });
  });
}
