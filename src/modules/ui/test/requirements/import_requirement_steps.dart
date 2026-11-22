import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_dialog.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../shared/import/import_dialog_harness.dart';
import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _openImport = 'open import';
const String _generate = 'Generate';
const String _generateStudyUnits = '/generate-study-units';
const Map<String, String> _studyUnitWording = {
  'flashcards': 'flashcards',
  'a note': 'note',
  'a test': 'test',
};

class _ImportOpener {
  const _ImportOpener(this.api);

  final ImportApi api;

  Future<void> open(BuildContext context) async {
    await showImportDialog(
      context: context,
      api: api,
      folderId: 'target-folder',
      folderName: 'Biology',
      pickFile: () async => null,
      pollInterval: Duration.zero,
    );
  }

  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => open(context),
      child: const Text(_openImport),
    );
  }
}

Set<String> _studyUnitsNamed(String wantedUnits) {
  final studyUnits = <String>{};

  for (final MapEntry(key: wording, value: studyUnit)
      in _studyUnitWording.entries) {
    if (wantedUnits.contains(wording)) {
      studyUnits.add(studyUnit);
    }
  }

  return studyUnits;
}

Future<void> _acceptImports(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  world.replies.addAll(importReplies());
}

Future<void> _openImportWithText(
  WidgetTester tester,
  String pastedText,
  UiWorld world,
) async {
  final opener = _ImportOpener(ImportApi(world.client()));

  await tester.pumpWidget(hostedPlainly(Builder(builder: opener.build)));
  await tester.tap(find.text(_openImport));
  await tester.pumpAndSettle();
  await chooseSource(tester, ImportSourceKind.text);
  await tester.enterText(find.byType(TextField), pastedText);
  await tester.pump();
}

Future<void> _generateFromDialog(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(DesignButton, _generate));
  await tester.pumpAndSettle();
}

Future<void> _importText(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  await _openImportWithText(tester, values.single, world);
  await _generateFromDialog(tester);
}

Future<void> _importTextWithout(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [pastedText, untickedUnit] = values;

  await _openImportWithText(tester, pastedText, world);
  await tester.tap(find.text(untickedUnit));
  await tester.pump();
  await _generateFromDialog(tester);
}

Future<void> _checkRequestedUnits(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [wantedUnits, importedText] = values;
  final request = sentBody(world.backend().sentTo(_generateStudyUnits).single);
  final requestedUnits = <String>{};

  for (final studyUnit in _studyUnitWording.values) {
    if (request.containsKey(studyUnit)) {
      requestedUnits.add(studyUnit);
    }
  }

  expect(request['text'], importedText);
  expect(requestedUnits, _studyUnitsNamed(wantedUnits));
}

final List<StepDefinition> importStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(r'^the backend accepts imports$'),
    _acceptImports,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I import the text "(.+)" in the app$'),
    _importText,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I import the text "(.+)" in the app without "(.+)"$'),
    _importTextWithout,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^the backend was asked to generate (.+) from "(.+)"$'),
    _checkRequestedUnits,
  ),
];
