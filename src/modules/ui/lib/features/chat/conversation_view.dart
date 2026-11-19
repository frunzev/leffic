import 'package:flutter/material.dart';

import '../../shared/api/chat_models.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import 'chat_bubble.dart';

const String _thinkingText = 'Thinking…';
const String _emptyTitle = 'No messages yet';
const double _logPadding = Spacing.step4;

class ConversationView extends StatelessWidget {
  const ConversationView({
    required this.conversation,
    required this.isWaiting,
    required this.failureMessage,
    super.key,
  });

  final List<ChatMessage> conversation;
  final bool isWaiting;
  final String? failureMessage;

  List<Widget> _bubbles() {
    final bubbles = <Widget>[];
    final failure = failureMessage;

    for (final message in conversation) {
      bubbles.add(ChatBubble(role: message.role, text: message.content));
    }

    if (isWaiting) {
      bubbles.add(
        const ChatBubble(role: ChatRole.assistant, text: _thinkingText),
      );
    }

    if (failure != null) {
      bubbles.add(ChatBubble(role: ChatRole.assistant, text: failure));
    }

    return bubbles;
  }

  Widget _buildLog(BuildContext context, BoxConstraints constraints) {
    final shortestContent = constraints.maxHeight - 2 * _logPadding;

    return SelectionArea(
      child: SingleChildScrollView(
        reverse: true,
        padding: const EdgeInsets.all(_logPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: shortestContent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.step3,
            children: _bubbles(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (conversation.isEmpty && !isWaiting) {
      return const _EmptyConversation();
    }

    return LayoutBuilder(builder: _buildLog);
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.step5),
        child: Text(
          _emptyTitle,
          textAlign: TextAlign.center,
          style: textStyleForSize(TextSizes.small).copyWith(
            color: DesignColors.of(context).inkTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
