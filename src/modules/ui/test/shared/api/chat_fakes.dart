import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:leffic/shared/api/chat_models.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';

List<Object?> sentConversation(http.Request request) {
  return sentBody(request)['conversation']! as List<Object?>;
}

ChatMessage generatedMessage(Random random) {
  return ChatMessage(
    role: oneOf(random, ChatRole.values),
    content: anyTextOf(random),
  );
}

List<ChatMessage> generatedConversation(Random random) {
  final count = integerBetween(random, 1, 8);
  final conversation = <ChatMessage>[];

  for (var index = 0; index < count; index++) {
    conversation.add(generatedMessage(random));
  }

  return conversation;
}
