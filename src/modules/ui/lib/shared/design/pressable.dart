import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

@immutable
class InteractionState {
  const InteractionState({
    required this.isEnabled,
    required this.isHovered,
    required this.isPressed,
    required this.isFocused,
  });

  final bool isEnabled;
  final bool isHovered;
  final bool isPressed;
  final bool isFocused;
}

typedef InteractionBuilder = Widget Function(
  BuildContext context,
  InteractionState state,
);

class Pressable extends StatefulWidget {
  const Pressable({
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    super.key,
  });

  final VoidCallback? onPressed;
  final InteractionBuilder builder;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  void _enter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  void _exit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });
  }

  void _showFocus(bool isFocused) {
    setState(() {
      _isFocused = isFocused;
    });
  }

  void _press(PointerDownEvent event) {
    setState(() {
      _isPressed = true;
    });
  }

  void _release(PointerEvent event) {
    setState(() {
      _isPressed = false;
    });
  }

  Object? _activate(ActivateIntent intent) {
    widget.onPressed?.call();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final state = InteractionState(
      isEnabled: isEnabled,
      isHovered: isEnabled && _isHovered,
      isPressed: isEnabled && _isPressed,
      isFocused: isEnabled && _isFocused,
    );
    final cursor = isEnabled
        ? SystemMouseCursors.click
        : SystemMouseCursors.forbidden;

    return MouseRegion(
      cursor: cursor,
      onEnter: _enter,
      onExit: _exit,
      child: FocusableActionDetector(
        enabled: isEnabled,
        onShowFocusHighlight: _showFocus,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
        },
        child: Listener(
          onPointerDown: isEnabled ? _press : null,
          onPointerUp: _release,
          onPointerCancel: _release,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: Semantics(
              button: true,
              enabled: isEnabled,
              label: widget.semanticLabel,
              child: widget.builder(context, state),
            ),
          ),
        ),
      ),
    );
  }
}
