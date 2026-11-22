import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/files/document_page_reports.dart';
import 'package:leffic/features/files/file_reader.dart';
import 'package:leffic/features/files/files_api.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../features/files/file_fakes.dart';
import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _fileBookmark = '/file-bookmark';
const String _putMethod = 'PUT';
const String _pdfExtension = 'pdf';

class _PageReporter {
  DocumentPageReports? reports;

  Widget build(DocumentPageReports pageReports) {
    reports = pageReports;

    return const SizedBox.shrink();
  }
}

Future<http.Response> _bookmarkReply(http.Request request) async {
  if (request.method == _putMethod) {
    return jsonReply({'page': sentBody(request)['page']});
  }

  return jsonReply({'page': null});
}

String _fileIdFor(String fileName) {
  return 'file-$fileName';
}

Future<void> _serveFile(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [pageCount, fileName] = values;

  world.replies[_fileBookmark] = _bookmarkReply;
  world.fileDetails[fileName] = detailsOpenedAt(
    null,
    pageCount: int.parse(pageCount),
  );
}

Future<void> _serveBookmarkedFile(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [pageCount, fileName, bookmarkedPage] = values;

  world.replies[_fileBookmark] = _bookmarkReply;
  world.fileDetails[fileName] = detailsOpenedAt(
    int.parse(bookmarkedPage),
    pageCount: int.parse(pageCount),
  );
}

Future<_PageReporter> _readFile(
  WidgetTester tester,
  UiWorld world,
  String fileName,
) async {
  final reporter = _PageReporter();
  final file = FileArguments(
    id: _fileIdFor(fileName),
    name: fileName,
    extension: _pdfExtension,
  );

  await tester.pumpWidget(
    hostedPlainly(
      FileReader(
        api: FilesApi(world.client()),
        file: file,
        details: world.fileDetails[fileName]!,
        documentBuilder: reporter.build,
        onGenerateStudyUnits: () {},
        onClose: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  return reporter;
}

Future<void> _openFile(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  await _readFile(tester, world, values.single);
}

Future<void> _scrollFile(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [fileName, page] = values;
  final reporter = await _readFile(tester, world, fileName);

  reporter.reports!.onVisiblePageChanged(int.parse(page));
  await tester.pump();
}

Future<void> _bookmarkPageInView(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  await tester.tap(find.bySemanticsLabel(RegExp(r'^Bookmark page \d+$')));
  await tester.pumpAndSettle();
}

Future<void> _checkSavedBookmark(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [page, fileName] = values;
  final saved = world.backend().sentTo(_fileBookmark).single;

  expect(saved.method, _putMethod);
  expect(sentBody(saved), {
    'file_id': _fileIdFor(fileName),
    'page': int.parse(page),
  });
}

Future<void> _checkRemovableBookmark(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final removeLabel = 'Remove the bookmark on page ${values.single}';

  expect(find.bySemanticsLabel(removeLabel), findsOneWidget);
}

final List<StepDefinition> fileStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(r'^the backend keeps bookmarks for the (\d+)-page file "(.+)"$'),
    _serveFile,
  ),
  StepDefinition(
    'Given',
    RegExp(
      r'^the backend keeps bookmarks for the (\d+)-page file "(.+)" '
      r'bookmarked on page (\d+)$',
    ),
    _serveBookmarkedFile,
  ),
  StepDefinition('When', RegExp(r'^I read "(.+)" in the app$'), _openFile),
  StepDefinition(
    'When',
    RegExp(r'^I read "(.+)" in the app as far as page (\d+)$'),
    _scrollFile,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I bookmark the page in view$'),
    _bookmarkPageInView,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^the backend saved page (\d+) of "(.+)"$'),
    _checkSavedBookmark,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^the app offers to remove the bookmark on page (\d+)$'),
    _checkRemovableBookmark,
  ),
];
