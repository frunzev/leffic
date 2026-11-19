import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/widgets/load_view.dart';

import '../../support/property.dart';

Widget _hosted(Widget child) => MaterialApp(home: Scaffold(body: child));

class _CountedLoad {
  _CountedLoad(this.gate);

  final Completer<String> gate;
  int count = 0;

  Future<String> load() {
    count++;

    return gate.future;
  }
}

void main() {
  testWidgets('LoadView property shows whatever value finished loading', (
    tester,
  ) async {
    final values = <String>[];
    forAll(wordOf, values.add, runs: 5);

    for (final value in values) {
      await tester.pumpWidget(
        _hosted(
          LoadView<String>(
            key: ValueKey(value),
            load: () async => value,
            builder: (context, loaded, reload) => Text('got $loaded'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('got $value'), findsOneWidget);
    }
  });

  testWidgets('LoadView property shows a failure with a retry', (tester) async {
    await tester.pumpWidget(
      _hosted(
        LoadView<String>(
          load: () async => throw StateError('broken backend'),
          builder: (context, loaded, reload) => Text(loaded),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('broken backend'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('LoadView property shows its placeholder until it loads', (
    tester,
  ) async {
    for (final value in examplesOf(wordOf, runs: 4)) {
      final counted = _CountedLoad(Completer<String>());

      await tester.pumpWidget(
        _hosted(
          LoadView<String>(
            key: ValueKey(value),
            load: counted.load,
            placeholder: (context, reload) =>
                TextButton(onPressed: reload, child: Text('waiting $value')),
            builder: (context, loaded, reload) => Text('got $loaded'),
          ),
        ),
      );

      expect(find.text('waiting $value'), findsOneWidget);

      await tester.tap(find.text('waiting $value'));
      await tester.pump();

      expect(counted.count, 2);

      counted.gate.complete(value);
      await tester.pumpAndSettle();

      expect(find.text('waiting $value'), findsNothing);
      expect(find.text('got $value'), findsOneWidget);
    }
  });

  testWidgets('FailureView property shows every message', (tester) async {
    final messages = <String>[];
    forAll(wordOf, messages.add, runs: 5);

    for (final message in messages) {
      await tester.pumpWidget(
        _hosted(FailureView(message: message, onRetry: () {})),
      );

      expect(find.text(message), findsOneWidget);
    }
  });
}
