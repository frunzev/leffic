import 'package:flutter/material.dart';

import 'design_metrics.dart';
import 'toast.dart';

const double _stackWidth = 360;

final class ShownToast {
  ShownToast(this.message);

  final ToastMessage message;
}

class ToastHost extends StatefulWidget {
  const ToastHost({required this.child, super.key});

  final Widget child;

  static ToastHostState of(BuildContext context) {
    final host = context.findAncestorStateOfType<ToastHostState>();

    if (host == null) {
      throw FlutterError('No ToastHost above this widget to show toasts in.');
    }

    return host;
  }

  @override
  State<ToastHost> createState() => ToastHostState();
}

class ToastHostState extends State<ToastHost> {
  List<ShownToast> _shown = const [];

  ShownToast show(ToastMessage message) {
    final shown = ShownToast(message);

    setState(() {
      _shown = [..._shown, shown];
    });

    return shown;
  }

  void dismiss(ShownToast dismissed) {
    setState(() {
      _shown = [
        for (final shown in _shown)
          if (!identical(shown, dismissed)) shown,
      ];
    });
  }

  Widget _toastFor(ShownToast shown) {
    return Toast(
      key: ObjectKey(shown),
      message: shown.message,
      onDismiss: () => dismiss(shown),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          right: Spacing.step4,
          bottom: Spacing.step4,
          width: _stackWidth,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.step2,
              children: [for (final shown in _shown) _toastFor(shown)],
            ),
          ),
        ),
      ],
    );
  }
}
