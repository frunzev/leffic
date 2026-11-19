import 'package:flutter/material.dart';

import '../../shared/api/chat_models.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';

const double _widestBubbleShare = 0.88;
const double _bubbleLineHeight = 1.5;
const Radius _bubbleCorner = Radius.circular(Radii.large);
const Radius _tuckedCorner = Radius.circular(Radii.small);

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.role, required this.text, super.key});

  final ChatRole role;
  final String text;

  Widget _buildBubble(BuildContext context, BoxConstraints constraints) {
    final colors = DesignColors.of(context);
    final isFromUser = role == ChatRole.user;
    final widestBubble = constraints.maxWidth * _widestBubbleShare;
    final corners = BorderRadius.only(
      topLeft: _bubbleCorner,
      topRight: _bubbleCorner,
      bottomLeft: isFromUser ? _bubbleCorner : _tuckedCorner,
      bottomRight: isFromUser ? _tuckedCorner : _bubbleCorner,
    );

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widestBubble),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isFromUser ? colors.brand : colors.surfaceTertiary,
            borderRadius: corners,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.step3,
              horizontal: Spacing.step4,
            ),
            child: Text(
              text,
              style: textStyleForSize(TextSizes.small).copyWith(
                color: isFromUser ? colors.onBrand : colors.ink,
                height: _bubbleLineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildBubble);
  }
}
