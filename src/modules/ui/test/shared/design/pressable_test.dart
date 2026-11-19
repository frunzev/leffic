import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/pressable.dart';

import '../../support/property.dart';

const Key _targetKey = Key('pressable target');
const int _mouseDevice = 1;

class _Recorder {
  final List<InteractionState> states = [];
  int presses = 0;

  void press() => presses++;

  Widget build(BuildContext context, InteractionState state) {
    states.add(state);

    return const SizedBox(key: _targetKey, width: 120, height: 40);
  }
}

Widget _hosted(_Recorder recorder, {required VoidCallback? onPressed}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Pressable(onPressed: onPressed, builder: recorder.build),
      ),
    ),
  );
}

Future<TestGesture> _hover(WidgetTester tester) async {
  final mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    pointer: _mouseDevice,
  );

  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(find.byKey(_targetKey)));
  await tester.pump();

  return mouse;
}

void main() {
  testWidgets('Pressable property reports hover and press, then fires once', (
    tester,
  ) async {
    for (final holdMilliseconds in examplesOf(
      (random) => integerBetween(random, 1, 400),
      runs: 4,
    )) {
      final recorder = _Recorder();

      await tester.pumpWidget(_hosted(recorder, onPressed: recorder.press));

      final mouse = await _hover(tester);

      expect(recorder.states.last.isHovered, isTrue);
      expect(recorder.states.last.isPressed, isFalse);

      await mouse.down(tester.getCenter(find.byKey(_targetKey)));
      await tester.pump(Duration(milliseconds: holdMilliseconds));

      expect(recorder.states.last.isPressed, isTrue);

      await mouse.up();
      await tester.pump();

      expect(recorder.states.last.isPressed, isFalse);
      expect(recorder.presses, 1);

      await mouse.removePointer();
    }
  });

  testWidgets('Pressable property never reacts while disabled', (tester) async {
    final recorder = _Recorder();

    await tester.pumpWidget(_hosted(recorder, onPressed: null));

    final mouse = await _hover(tester);

    await mouse.down(tester.getCenter(find.byKey(_targetKey)));
    await tester.pump();
    await mouse.up();
    await tester.pump();
    await mouse.removePointer();

    for (final state in recorder.states) {
      expect(state.isEnabled, isFalse);
      expect(state.isHovered, isFalse);
      expect(state.isPressed, isFalse);
      expect(state.isFocused, isFalse);
    }
  });

  testWidgets('Pressable property shows the cursor its state allows', (
    tester,
  ) async {
    for (final isEnabled in [true, false]) {
      final recorder = _Recorder();

      await tester.pumpWidget(
        _hosted(recorder, onPressed: isEnabled ? recorder.press : null),
      );
      final mouse = await _hover(tester);
      final tracker = RendererBinding.instance.mouseTracker;

      expect(
        tracker.debugDeviceActiveCursor(_mouseDevice),
        isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      );

      await mouse.removePointer();
    }
  });

  testWidgets('Pressable property shows keyboard focus and activates', (
    tester,
  ) async {
    for (final activationKey in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
    ]) {
      final recorder = _Recorder();

      await tester.pumpWidget(_hosted(recorder, onPressed: recorder.press));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(recorder.states.last.isFocused, isTrue);

      await tester.sendKeyEvent(activationKey);
      await tester.pump();

      expect(recorder.presses, 1);
    }
  });
}
