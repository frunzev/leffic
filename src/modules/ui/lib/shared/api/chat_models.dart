import 'json_reading.dart';

enum ChatRole {
  user('user'),
  assistant('assistant');

  const ChatRole(this.wireName);

  final String wireName;
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final ChatRole role;
  final String content;

  JsonObject toJson() => {'role': role.wireName, 'content': content};
}
