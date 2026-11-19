import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flashcard_models.dart';

class ReviewShortcuts extends StatelessWidget {
  const ReviewShortcuts({
    required this.onReveal,
    required this.onRate,
    required this.child,
    super.key,
  });

  final VoidCallback? onReveal;
  final ValueChanged<FlashcardRating>? onRate;
  final Widget child;

  Map<ShortcutActivator, VoidCallback> _bindings() {
    final bindings = <ShortcutActivator, VoidCallback>{};
    final reveal = onReveal;
    final rate = onRate;

    if (reveal != null) {
      bindings[const SingleActivator(LogicalKeyboardKey.space)] = reveal;
    }

    if (rate != null) {
      for (final rating in FlashcardRating.values) {
        bindings[CharacterActivator('${rating.score}')] = () => rate(rating);
      }
    }

    return bindings;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: _bindings(),
      child: Focus(autofocus: true, child: child),
    );
  }
}
