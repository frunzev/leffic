import 'api_client.dart';
import 'chat_models.dart';
import 'json_reading.dart';

class ChatApi {
  const ChatApi(this.client);

  final ApiClient client;

  Future<String> ask(List<ChatMessage> conversation) async {
    final sentMessages = <JsonObject>[];

    for (final message in conversation) {
      sentMessages.add(message.toJson());
    }

    final reply = await client.sendJson('POST', '/chat', {
      'conversation': sentMessages,
    });

    return readText(asObject(reply), 'answer');
  }
}
