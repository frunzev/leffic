import 'package:flutter/widgets.dart';

class AskPanelController extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void open() => _show(isOpen: true);

  void close() => _show(isOpen: false);

  void toggle() => _show(isOpen: !_isOpen);

  void _show({required bool isOpen}) {
    if (_isOpen == isOpen) {
      return;
    }

    _isOpen = isOpen;
    notifyListeners();
  }
}

class AskPanelScope extends InheritedNotifier<AskPanelController> {
  const AskPanelScope({
    required this.controller,
    required this.panel,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  final AskPanelController controller;
  final Widget panel;

  static AskPanelScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AskPanelScope>();

    if (scope == null) {
      throw FlutterError('No AskPanelScope above this widget.');
    }

    return scope;
  }

  @override
  bool updateShouldNotify(AskPanelScope oldWidget) {
    return oldWidget.controller != controller || oldWidget.panel != panel;
  }
}
