import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/design_text_field.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/design/spinner.dart';
import 'package:leffic/shared/import/dropzone.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_dialog.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Size _designWindow = Size(1440, 900);
const double _modalWidth = 600;
const double _bodyInset = 25;

Future<void> _openImport(WidgetTester tester, FakeBackend backend) async {
  tester.view.physicalSize = _designWindow;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    hostedPlainly(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showImportDialog(
            context: context,
            api: ImportApi(backend.client()),
            folderId: 'home',
            folderName: 'Home',
            pickFile: () async =>
                UploadedFile(name: 'notes.txt', bytes: Uint8List(1200000)),
            pollInterval: Duration.zero,
          ),
          child: const Text('open import'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open import'));
  await tester.pumpAndSettle();
}

Rect _segmentedRect(WidgetTester tester) {
  return tester.getRect(find.byType(SegmentedControl<ImportSourceKind>));
}

void main() {
  testWidgets('ImportModal property lays the source step out like the CSS', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await _openImport(tester, FakeBackend({}));

    final modal = tester.getRect(find.byType(DesignModal));
    final segmented = _segmentedRect(tester);
    final dropzone = tester.getRect(find.byType(Dropzone));
    final hint = tester.getRect(find.text('Choose a file first.'));
    final hintStyle = renderedStyleOf(tester, 'Choose a file first.');

    expect(modal.width, _modalWidth);
    expect(segmented.left - modal.left, _bodyInset);
    expect(segmented.width, _modalWidth - 2 * _bodyInset);
    expect(segmented.height, 42);
    expect(dropzone.top - segmented.bottom, 16);
    expect(dropzone.width, segmented.width);
    expect(hint.left - modal.left, _bodyInset);
    expect(hintStyle.fontSize, 14);
    expect(hintStyle.color, colors.inkTertiary);
  });

  testWidgets('ImportModal property places each source panel like the CSS', (
    tester,
  ) async {
    const panelGaps = {
      ImportSourceKind.link: ('Page address', 16.0),
      ImportSourceKind.text: ('Text', 0.0),
      ImportSourceKind.topic: ('Topic', 16.0),
    };

    await _openImport(tester, FakeBackend({}));

    for (final kind in examplesOf(
      (random) => oneOf(random, panelGaps.keys.toList()),
      runs: 6,
    )) {
      final (label, gap) = panelGaps[kind]!;

      await tester.tap(find.text(kind.label));
      await tester.pumpAndSettle();

      final labelRect = tester.getRect(find.text(label).last);

      expect(labelRect.top - _segmentedRect(tester).bottom, gap);
    }
  });

  testWidgets('ImportModal property makes the text box eight rows tall', (
    tester,
  ) async {
    await _openImport(tester, FakeBackend({}));
    await tester.tap(find.text(ImportSourceKind.text.label));
    await tester.pumpAndSettle();

    final textArea = tester.getRect(find.byType(DesignTextArea));

    expect(textArea.height, closeTo(8 * 16 * 1.55 + 24 + 2, 0.01));
    expect(find.text('Generate'), findsNWidgets(2));
  });

  testWidgets('ImportModal property centres the reading notice', (
    tester,
  ) async {
    final backend = FakeBackend({
      '/upload-files': answerWith({
        'file_metadata': [
          {'file_id': 'stored-file'},
        ],
      }),
      '/extract-text': (request) => Completer<http.Response>().future,
    });

    await _openImport(tester, backend);
    await tester.tap(find.text('Browse files'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();

    final modal = tester.getRect(find.byType(DesignModal));
    final spinner = tester.getRect(find.byType(Spinner));
    final text = tester.getRect(find.text('Reading notes.txt…'));
    final colors = DesignColors.forBrightness(Brightness.light);

    expect(spinner.center.dx, closeTo(modal.center.dx, 0.01));
    expect(text.top - spinner.bottom, 12);
    expect(renderedStyleOf(tester, 'Reading notes.txt…').fontSize, 14);
    expect(renderedStyleOf(tester, 'Reading notes.txt…').color, colors.ink);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
  });
}
