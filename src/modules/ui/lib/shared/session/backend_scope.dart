import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../backend/backend_process.dart';

class BackendLink extends ValueNotifier<ApiClient?> {
  BackendLink() : super(null);

  RunningBackend? _running;

  void connect(ApiClient client, RunningBackend running) {
    _running = running;
    value = client;
  }

  Future<void> disconnect() async {
    final running = _running;

    _running = null;
    value = null;

    if (running != null) {
      await running.stop();
    }
  }
}

class BackendScope extends InheritedNotifier<BackendLink> {
  const BackendScope({
    required BackendLink link,
    required super.child,
    super.key,
  }) : super(notifier: link);

  static BackendLink linkOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BackendScope>();

    if (scope == null) {
      throw StateError('No BackendScope above this widget');
    }

    return scope.notifier!;
  }

  static ApiClient clientOf(BuildContext context) {
    final client = linkOf(context).value;

    if (client == null) {
      throw StateError('The backend is not connected yet');
    }

    return client;
  }
}
