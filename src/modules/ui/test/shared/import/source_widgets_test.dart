import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/import/chosen_file.dart';
import 'package:leffic/shared/import/dropzone.dart';
import 'package:leffic/shared/import/file_source_panel.dart';
import 'package:leffic/shared/import/import_source.dart';
import 'package:leffic/shared/import/page_range_fields.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'import_fakes.dart';

const double _panelWidth = 550;
const String _dropzoneText = 'Drop a file here';
const String _dropzoneHint = 'PDF, DOCX, PPTX or TXT · up to 20 MB';

Widget _sized(Widget child) {
  return hostedPlainly(
    Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: _panelWidth, child: child),
    ),
  );
}

Widget _filePanel(UploadedFile? file, List<String> calls) {
  return _sized(
    FileSourcePanel(
      file: file,
      firstPage: TextEditingController(),
      lastPage: TextEditingController(),
      onBrowse: () => calls.add('browse'),
      onRemove: () => calls.add('remove'),
      onTyped: (text) => calls.add('typed $text'),
    ),
  );
}

void main() {
  test('evenDashCount property leaves a gap between zero and two dashes', () {
    forAll((random) => integerBetween(random, 20, 4000) / 3, (pathLength) {
      final dashCount = evenDashCount(pathLength);
      final gap = pathLength / dashCount - dashLength;

      expect(dashCount, greaterThanOrEqualTo(1));
      expect(gap, greaterThan(0));
      expect(gap, lessThan(dashLength * 2));
    });
  });

  testWidgets('Dropzone property spaces its parts like app-import.css', (
    tester,
  ) async {
    for (final width in examplesOf(
      (random) => integerBetween(random, 320, 700).toDouble(),
      runs: 5,
    )) {
      final browses = <String>[];

      await tester.pumpWidget(
        hostedPlainly(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: Dropzone(onBrowse: () => browses.add('browse')),
            ),
          ),
        ),
      );

      final zone = tester.getRect(find.byType(Dropzone));
      final icon = tester.getRect(find.byType(DesignIcon).first);
      final text = tester.getRect(find.text(_dropzoneText));
      final button = tester.getRect(find.byType(DesignButton));
      final hint = tester.getRect(find.text(_dropzoneHint));
      final colors = DesignColors.forBrightness(Brightness.light);

      expect(zone.width, width);
      expect(icon.top - zone.top, 33);
      expect(icon.size, const Size(20, 20));
      expect(icon.center.dx, closeTo(zone.center.dx, 0.01));
      expect(text.top - icon.bottom, 8);
      expect(button.top - text.bottom, 8);
      expect(button.height, 40);
      expect(hint.top - button.bottom, 8);
      expect(zone.bottom - hint.bottom, 33);
      expect(renderedStyleOf(tester, _dropzoneText).fontSize, 14);
      expect(renderedStyleOf(tester, _dropzoneText).color, colors.ink);
      expect(renderedStyleOf(tester, _dropzoneHint).fontSize, 12);
      expect(renderedStyleOf(tester, _dropzoneHint).color, colors.inkTertiary);

      await tester.tap(find.text('Browse files'));

      expect(browses, ['browse']);
    }
  });

  test('describeFileSize property names the size in the fitting unit', () {
    forAll(
      (random) => oneOf(random, [
        random.nextInt(1000),
        integerBetween(random, 1000, 999999),
        integerBetween(random, 1000000, 90000000),
      ]),
      (byteCount) {
        final label = describeFileSize(byteCount);

        if (byteCount < 1000) {
          expect(label, '$byteCount B');
        } else if (byteCount < 1000000) {
          expect(label, '${byteCount ~/ 1000} KB');
        } else {
          expect(label, '${(byteCount / 1000000).toStringAsFixed(1)} MB');
        }
      },
    );
  });

  testWidgets('ChosenFile property shows the file like app-import.css', (
    tester,
  ) async {
    for (final file in examplesOf(
      (random) => generatedFile(random, oneOf(random, unpagedExtensions)),
      runs: 5,
    )) {
      final removals = <String>[];
      final colors = DesignColors.forBrightness(Brightness.light);

      await tester.pumpWidget(
        _sized(ChosenFile(file: file, onRemove: () => removals.add(file.name))),
      );

      final row = tester.getRect(find.byType(ChosenFile));
      final icon = tester.getRect(find.byType(DesignIcon).first);
      final name = tester.getRect(find.text(file.name));
      final size = describeFileSize(file.bytes.length);
      final remove = tester.getRect(
        find.bySemanticsLabel('Remove ${file.name}'),
      );

      expect(row.height, 66);
      expect(icon.left - row.left, 17);
      expect(name.left - icon.right, 12);
      expect(row.right - remove.right, 17);
      expect(remove.size, const Size(40, 40));
      expect(renderedStyleOf(tester, file.name).fontSize, 14);
      expect(renderedStyleOf(tester, size).fontSize, 12);
      expect(renderedStyleOf(tester, size).color, colors.inkTertiary);

      await tester.tap(find.bySemanticsLabel('Remove ${file.name}'));

      expect(removals, [file.name]);
    }
  });

  testWidgets('FileSourcePanel property asks for a file until one exists', (
    tester,
  ) async {
    final calls = <String>[];

    await tester.pumpWidget(_filePanel(null, calls));
    await tester.tap(find.text('Browse files'));

    expect(find.byType(Dropzone), findsOneWidget);
    expect(calls, ['browse']);
  });

  testWidgets('FileSourcePanel property asks for pages of paged files only', (
    tester,
  ) async {
    for (final file in examplesOf(
      (random) => generatedFile(
        random,
        oneOf(random, [...pagedExtensions, ...unpagedExtensions]),
      ),
      runs: 8,
    )) {
      final calls = <String>[];

      await tester.pumpWidget(_filePanel(file, calls));
      await tester.tap(find.bySemanticsLabel('Remove ${file.name}'));

      expect(find.text(file.name), findsOneWidget);
      expect(
        find.byType(PageRangeFields),
        isPagedFileName(file.name) ? findsOneWidget : findsNothing,
      );
      expect(calls, ['remove']);
    }
  });

  testWidgets('PageRangeFields property keeps and reports both pages', (
    tester,
  ) async {
    for (final (first, last) in examplesOf(
      (random) => ('${integerBetween(random, 1, 9)}', '${random.nextInt(99)}'),
      runs: 5,
    )) {
      final calls = <String>[];
      final firstPage = TextEditingController();
      final lastPage = TextEditingController();

      await tester.pumpWidget(
        _sized(
          PageRangeFields(
            key: UniqueKey(),
            firstPage: firstPage,
            lastPage: lastPage,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, first);
      await tester.enterText(find.byType(TextField).last, last);

      expect(calls, [first, last]);
      expect(firstPage.text, first);
      expect(lastPage.text, last);
      expect(find.text('Pages'), findsOneWidget);
      expect(find.text('to'), findsOneWidget);
    }
  });

  testWidgets('ChosenFile property sizes a picked file in megabytes', (
    tester,
  ) async {
    for (final megabytes in examplesOf(
      (random) => integerBetween(random, 1, 19),
      runs: 3,
    )) {
      final file = UploadedFile(
        name: 'action-potentials.pdf',
        bytes: Uint8List(megabytes * 1000000 + 200000),
      );

      await tester.pumpWidget(_sized(ChosenFile(file: file, onRemove: () {})));

      expect(find.text('$megabytes.2 MB'), findsOneWidget);
    }
  });
}
