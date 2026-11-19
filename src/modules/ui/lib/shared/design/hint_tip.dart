import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';
import 'focus_outline.dart';
import 'pressable.dart';

const double _buttonSide = 18;
const double _bubbleWidth = 232;
const double _bubbleLineHeight = 1.45;
const Offset _bubbleOffset = Offset(-Spacing.step2, Spacing.step2);
const String _questionMark = '?';

class HintTipButton extends StatelessWidget {
  const HintTipButton({required this.state, super.key});

  final InteractionState state;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final isLit = state.isHovered;

    return FocusOutline(
      state: state,
      borderRadius: Radii.pill,
      child: SizedBox.square(
        dimension: _buttonSide,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isLit ? colors.brandSurfaceStrong : colors.surfaceTertiary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _questionMark,
              style: textStyleForSize(TextSizes.extraSmall).copyWith(
                color: isLit ? colors.brandStrong : colors.inkTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HintTipBubble extends StatelessWidget {
  const HintTipBubble({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return SizedBox(
      width: _bubbleWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: BorderRadius.circular(Radii.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.step2,
            horizontal: Spacing.step3,
          ),
          child: Text(
            text,
            style: textStyleForSize(TextSizes.extraSmall)
                .copyWith(color: colors.surface, height: _bubbleLineHeight),
          ),
        ),
      ),
    );
  }
}

class HintTip extends StatefulWidget {
  const HintTip({required this.text, required this.semanticLabel, super.key});

  final String text;
  final String semanticLabel;

  @override
  State<HintTip> createState() => _HintTipState();
}

class _HintTipState extends State<HintTip> {
  final OverlayPortalController _tip = OverlayPortalController();
  final LayerLink _anchorLink = LayerLink();
  bool _isButtonHovered = false;
  bool _isTipHovered = false;
  bool _isFocused = false;

  bool get _isTipShown => _isButtonHovered || _isTipHovered || _isFocused;

  @override
  void initState() {
    super.initState();
    _tip.show();
  }

  void _enterButton(PointerEnterEvent event) {
    setState(() {
      _isButtonHovered = true;
    });
  }

  void _exitButton(PointerExitEvent event) {
    setState(() {
      _isButtonHovered = false;
    });
  }

  void _enterTip(PointerEnterEvent event) {
    setState(() {
      _isTipHovered = true;
    });
  }

  void _exitTip(PointerExitEvent event) {
    setState(() {
      _isTipHovered = false;
    });
  }

  void _showFocus(bool isFocused) {
    setState(() {
      _isFocused = isFocused;
    });
  }

  Widget _buildTip(BuildContext context) {
    final isShown = _isTipShown;

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _anchorLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        offset: _bubbleOffset,
        child: IgnorePointer(
          ignoring: !isShown,
          child: MouseRegion(
            onEnter: _enterTip,
            onExit: _exitTip,
            child: AnimatedOpacity(
              opacity: isShown ? 1 : 0,
              duration: Motion.duration,
              curve: Motion.curve,
              child: HintTipBubble(text: widget.text),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = InteractionState(
      isEnabled: true,
      isHovered: _isButtonHovered,
      isPressed: false,
      isFocused: _isFocused,
    );

    return CompositedTransformTarget(
      link: _anchorLink,
      child: OverlayPortal(
        controller: _tip,
        overlayChildBuilder: _buildTip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: _enterButton,
          onExit: _exitButton,
          child: FocusableActionDetector(
            onShowFocusHighlight: _showFocus,
            child: Semantics(
              button: true,
              label: widget.semanticLabel,
              child: ExcludeSemantics(child: HintTipButton(state: state)),
            ),
          ),
        ),
      ),
    );
  }
}
