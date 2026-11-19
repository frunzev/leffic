import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/input_frame.dart';
import '../../shared/design/pressable.dart';
import '../../shared/design/surface_box.dart';

const String _placeholder = 'Ask a question';
const int _inputRows = 3;
const double _inputLineHeight = 1.5;
const double _browserTextareaPadding = 2;
const double _inputHeight =
    _inputRows * TextSizes.medium * _inputLineHeight +
    2 * _browserTextareaPadding;

class ChatComposer extends StatefulWidget {
  const ChatComposer({required this.draft, required this.onSend, super.key});

  final TextEditingController draft;
  final ValueChanged<String>? onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(_showFocus);
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    super.dispose();
  }

  void _showFocus() {
    setState(() {});
  }

  void _send() {
    final onSend = widget.onSend;
    final question = widget.draft.text.trim();

    if (onSend == null || question.isEmpty) {
      return;
    }

    onSend(question);
    widget.draft.clear();
  }

  Widget _buildInput(DesignColors colors) {
    final inputStyle = DefaultTextStyle.of(context).style.merge(
      textStyleForSize(TextSizes.medium)
          .copyWith(color: colors.ink, height: _inputLineHeight),
    );

    return SizedBox(
      height: _inputHeight,
      child: TextField(
        controller: widget.draft,
        focusNode: _inputFocus,
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        textInputAction: TextInputAction.send,
        onEditingComplete: _send,
        style: inputStyle,
        cursorColor: colors.ink,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: _placeholder,
          hintStyle: inputStyle.copyWith(color: colors.inkTertiary),
          contentPadding: const EdgeInsets.all(_browserTextareaPadding),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final composeState = InteractionState(
      isEnabled: true,
      isHovered: false,
      isPressed: false,
      isFocused: _inputFocus.hasFocus,
    );
    final look = inputLookOf(
      state: composeState,
      validity: FieldValidity.valid,
      colors: colors,
      shadows: DesignShadows.of(context),
    );
    final isSendingOff = widget.onSend == null;

    return Padding(
      padding: const EdgeInsets.all(Spacing.step4),
      child: SurfaceBox(
        look: look,
        borderRadius: Radii.large,
        padding: const EdgeInsets.all(Spacing.step3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.step2,
          children: [
            _buildInput(colors),
            Align(
              alignment: Alignment.centerRight,
              child: DesignIconButton(
                icon: DesignIcons.send,
                semanticLabel: 'Send',
                onPressed: isSendingOff ? null : _send,
                variant: ButtonVariant.primary,
                dimension: ControlHeights.small,
                borderRadius: Radii.pill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
