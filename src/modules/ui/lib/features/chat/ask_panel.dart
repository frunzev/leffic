import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/api/chat_api.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/widgets/ask_panel_scope.dart';
import 'ask_panel_head.dart';
import 'chat_composer.dart';
import 'chat_conversation.dart';
import 'conversation_view.dart';

class AskPanel extends StatelessWidget {
  const AskPanel({required this.conversation, required this.draft, super.key});

  final ChatConversation conversation;
  final TextEditingController draft;

  void _send(BuildContext context, String question) {
    final chatApi = ChatApi(BackendScope.clientOf(context));

    unawaited(conversation.ask(question, chatApi: chatApi));
  }

  Widget _buildPanel(BuildContext context, Widget? child) {
    final colors = DesignColors.of(context);
    final shadows = DesignShadows.of(context);
    final askPanel = AskPanelScope.of(context).controller;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.line)),
        boxShadow: shadows.level2,
      ),
      foregroundDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: shadows.edgeHighlight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AskPanelHead(onClose: askPanel.close),
          Expanded(
            child: ConversationView(
              conversation: conversation.messages,
              isWaiting: conversation.isWaiting,
              failureMessage: conversation.failureMessage,
            ),
          ),
          ChatComposer(
            draft: draft,
            onSend: conversation.isWaiting
                ? null
                : (question) => _send(context, question),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: conversation, builder: _buildPanel);
  }
}
