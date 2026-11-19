import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/folder_test_page.dart';
import 'package:leffic/features/assessment/test_page.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/session/backend_scope.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import 'assessment_shot_data.dart';
import 'shot_support.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void _useFreshSupportDirectory() {
  final directory = Directory.systemTemp.createTempSync('leffic-shots');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    _pathProviderChannel,
    (call) async => directory.path,
  );
  addTearDown(() {
    messenger.setMockMethodCallHandler(_pathProviderChannel, null);
    directory.deleteSync(recursive: true);
  });
}

Widget _testPage(ShotTest test) {
  return BackendScope(
    link: AssessmentShotBackend(test).link(),
    child: const TestPage(arguments: UnitArguments(id: 'neuron-test')),
  );
}

Widget _mixedPage(ShotTest test) {
  return BackendScope(
    link: AssessmentShotBackend(test).link(),
    child: const FolderTestPage(
      arguments: UnitArguments(id: homeFolderId, name: 'Home'),
    ),
  );
}

Future<void> _pumpTest(
  WidgetTester tester,
  Brightness brightness,
  Widget page,
) async {
  _useFreshSupportDirectory();
  await pumpShotApp(
    tester,
    brightness: brightness,
    askPanel: AskPanelController(),
    panel: surfacePanelFor(brightness),
    home: page,
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _goForward(WidgetTester tester, int steps) async {
  for (var step = 0; step < steps; step++) {
    await tester.runAsync(() async {
      await tester.tap(find.text('Next'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }
}

Future<void> _openQuestionEditor(WidgetTester tester) async {
  await openDotsMenu(tester);
  await tester.tap(find.text('Edit question'));
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('test question in ${brightness.name}', (tester) async {
      await _pumpTest(tester, brightness, _testPage(neuronTest));
      await _goForward(tester, neuronTest.position - 1);
      await saveShot(tester, 'test-question', brightness);
      releaseDesktopWindow();
    });

    testWidgets('test item edit in ${brightness.name}', (tester) async {
      await _pumpTest(tester, brightness, _testPage(neuronTest));
      await _goForward(tester, neuronTest.position - 1);
      await _openQuestionEditor(tester);
      await saveShot(tester, 'test-item-edit', brightness);
      releaseDesktopWindow();
    });

    testWidgets('test result in ${brightness.name}', (tester) async {
      await _pumpTest(tester, brightness, _testPage(neuronTest));
      await _goForward(tester, neuronTest.totalItems - 1);
      await tester.runAsync(() async {
        await tester.tap(find.text('Finish'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      await saveShot(tester, 'test-result', brightness);
      releaseDesktopWindow();
    });

    testWidgets('test empty in ${brightness.name}', (tester) async {
      await _pumpTest(tester, brightness, _testPage(emptyTest));
      await saveShot(tester, 'test-empty', brightness);
      releaseDesktopWindow();
    });

    testWidgets('test mixed in ${brightness.name}', (tester) async {
      await _pumpTest(tester, brightness, _mixedPage(homeMixedTest));
      await _goForward(tester, homeMixedTest.position - 1);
      await saveShot(tester, 'test-mixed', brightness);
      releaseDesktopWindow();
    });
  }
}
