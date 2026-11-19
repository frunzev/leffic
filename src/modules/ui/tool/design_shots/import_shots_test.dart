import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/import/amount_choice.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_dialog.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import 'folder_shot_data.dart';
import 'shot_backend.dart';
import 'shot_support.dart';

typedef _ShotSteps = Future<void> Function(WidgetTester tester);

const String _designFileName = 'action-potentials.pdf';
const int _designFileBytes = 1200000;
const String _designLink = 'https://en.wikipedia.org/wiki/Action_potential';
const String _designTopic = 'Action potentials';
const int _feynmanAmountRow = 1;
const String _pastedText =
    'A neuron at rest sits near −70 mV. The sodium–potassium pump moves '
    'three sodium ions out for every two potassium ions in, and potassium '
    'leak channels let potassium drift back out.\n\n'
    'When a stimulus pushes the membrane past roughly −55 mV, voltage-gated '
    'sodium channels open and sodium floods in.';
const String _extractedText =
    'Action potentials\n\n'
    'The action potential is the electrical signal a neuron uses to carry '
    'information along its axon. It is all-or-nothing: once the membrane '
    'crosses threshold, the full spike follows.\n\n'
    '1. Resting state — the membrane sits near −70 mV, held there by the '
    'sodium–potassium pump and potassium leak channels.\n\n'
    '2. Depolarisation — a stimulus past roughly −55 mV opens '
    'voltage-gated sodium channels, and the potential swings to about '
    '+40 mV.\n\n'
    '3. Repolarisation — sodium channels inactivate, potassium channels '
    'open, and potassium leaves the cell.';

Future<UploadedFile?> _pickDesignFile() async {
  return UploadedFile(
    name: _designFileName,
    bytes: Uint8List(_designFileBytes),
  );
}

Future<http.Response> _answeredExtraction(http.Request request) async {
  return shotJsonReply({'text': _extractedText});
}

class _ImportReplies {
  const _ImportReplies({required this.extraction});

  final ShotReply extraction;

  Future<http.Response> answer(http.Request request) async {
    return switch (request.url.path) {
      '/upload-files' => shotJsonReply({
        'file_metadata': [
          {'file_id': 'stored-file'},
        ],
      }),
      '/extract-text' => await extraction(request),
      '/generate-study-units' => shotJsonReply({
        'note_task_id': 'note-task',
        'flashcard_task_ids': ['flashcards-task'],
      }),
      _ => await shotNeverReply(request),
    };
  }
}

Future<void> _openImport(
  WidgetTester tester,
  Brightness brightness,
  _ImportReplies replies,
) async {
  await pumpShotApp(
    tester,
    brightness: brightness,
    askPanel: AskPanelController(),
    panel: const SizedBox.shrink(),
    home: shotFolderPage(homeFolderId, filledHome),
  );
  await tester.pump();

  final page = tester.element(find.byType(AppShell));

  showImportDialog(
    context: page,
    api: ImportApi(shotApiClient(replies.answer)),
    folderId: 'home',
    folderName: 'Home',
    pickFile: _pickDesignFile,
    pollInterval: Duration.zero,
  ).ignore();
  await tester.pump();
}

Future<void> _typeUnfocused(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await tester.pump();
}

Future<void> _chooseFile(WidgetTester tester) async {
  await _tapText(tester, 'Browse files');
  await tester.pump();
}

Future<void> _continueWithFile(WidgetTester tester) async {
  await _chooseFile(tester);
  await _tapText(tester, 'Continue');
  await tester.pump();
}

Future<void> _showSourceStep(WidgetTester tester) async {
  await tester.pump();
}

Future<void> _typeLink(WidgetTester tester) async {
  await _tapText(tester, 'Link');
  await _typeUnfocused(tester, _designLink);
}

Future<void> _typeTopic(WidgetTester tester) async {
  await _tapText(tester, 'Topic');
  await _typeUnfocused(tester, _designTopic);
}

Future<void> _pasteText(WidgetTester tester) async {
  await _tapText(tester, 'Text');
  await _typeUnfocused(tester, _pastedText);
  await _tapText(tester, 'Feynman');
  await _tapText(tester, AmountMode.custom.label);
  await tester.enterText(find.byType(TextField).at(1), '45');
  await tester.pump();
  await tester.tap(
    find.descendant(
      of: find.byType(SegmentedControl<AmountMode>).at(_feynmanAmountRow),
      matching: find.text(AmountMode.ten.label),
    ),
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

Future<void> _generateFromReview(WidgetTester tester) async {
  await _continueWithFile(tester);
  await tester.tap(find.widgetWithText(DesignButton, 'Generate'));
  await tester.pump();
}

const _ImportReplies _answering = _ImportReplies(
  extraction: _answeredExtraction,
);
const _ImportReplies _stillReading = _ImportReplies(extraction: shotNeverReply);

const Map<String, (_ImportReplies, _ShotSteps)> _scenarios = {
  'import-file': (_answering, _showSourceStep),
  'import-file-ready': (_answering, _chooseFile),
  'import-link': (_answering, _typeLink),
  'import-topic': (_answering, _typeTopic),
  'import-text': (_answering, _pasteText),
  'import-extracting': (_stillReading, _continueWithFile),
  'import-review': (_answering, _continueWithFile),
  'import-generating': (_answering, _generateFromReview),
};

void main() {
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: (replies, steps))
        in _scenarios.entries) {
      testWidgets('$name in ${brightness.name}', (tester) async {
        await _openImport(tester, brightness, replies);
        await steps(tester);
        await saveShot(tester, name, brightness);
        releaseDesktopWindow();
      });
    }
  }
}
