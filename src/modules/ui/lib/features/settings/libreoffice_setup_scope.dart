import 'package:flutter/widgets.dart';

import 'libreoffice_setup.dart';

class LibreOfficeSetupScope extends InheritedWidget {
  const LibreOfficeSetupScope({
    required this.setup,
    required super.child,
    super.key,
  });

  final LibreOfficeSetup setup;

  static LibreOfficeSetup of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LibreOfficeSetupScope>();

    if (scope == null) {
      throw FlutterError('No LibreOfficeSetupScope above this widget.');
    }

    return scope.setup;
  }

  @override
  bool updateShouldNotify(LibreOfficeSetupScope oldWidget) {
    return oldWidget.setup != setup;
  }
}
