import 'package:flutter/foundation.dart';

import '../../shared/api/chat_api.dart';
import '../../shared/api/chat_models.dart';
import 'chat_failure.dart';

class ChatConversation extends ChangeNotifier {
  List<ChatMessage> _messages = const [];
  bool _isWaiting = false;
  String? _failureMessage;

  List<ChatMessage> get messages => _messages;

  bool get isWaiting => _isWaiting;

  String? get failureMessage => _failureMessage;

  Future<void> ask(String question, {required ChatApi chatApi}) async {
    final askedMessage = ChatMessage(role: ChatRole.user, content: question);

    _messages = [..._messages, askedMessage];
    _isWaiting = true;
    _failureMessage = null;
    notifyListeners();

    final String answer;

    try {
      answer = await chatApi.ask(_messages);
    } on Exception catch (failure) {
      _failureMessage = chatFailureMessage(failure);
      _isWaiting = false;
      notifyListeners();
      return;
    }

    final answerMessage = ChatMessage(
      role: ChatRole.assistant,
      content: answer,
    );

    _messages = [..._messages, answerMessage];
    _isWaiting = false;
    notifyListeners();
  }
}
