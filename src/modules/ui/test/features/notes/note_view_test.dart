import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_foot.dart';
import 'package:leffic/features/notes/note_models.dart';
import 'package:leffic/features/notes/note_view.dart';
import 'package:leffic/features/notes/reading_time.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _bodyKey = Key('note body');
const double _stageInset = 40;
const double _cardInset = 49;
const NotesProgress _folderProgress = NotesProgress(read: 12, total: 13);

Note _generatedNote(int runIndex, String name, List<String> words) {
  return Note(
    name: 'Note $runIndex $name',
    content: '<p>${words.join(' ')}</p>',
    isRead: runIndex.isEven,
    folderId: 'folder-$runIndex',
    source: null,
  );
}

Note _namedNote(String name, String content, {required bool isRead}) {
  return Note(
    name: name,
    content: content,
    isRead: isRead,
    folderId: 'folder',
    source: null,
  );
}

Widget _noteHostedIn(Brightness brightness, Note note, double bodyHeight) {
  return hostedInTheme(
    NoteView(
      note: note,
      progress: _folderProgress,
      body: SizedBox(key: _bodyKey, height: bodyHeight),
      markRead: () async {},
    ),
    brightness: brightness,
  );
}

void _useSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('NoteView property shows the name and the reading time', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (
        wordOf(random),
        List.generate(integerBetween(random, 0, 700), (index) => 'word'),
      ),
      runs: 8,
    );

    for (var runIndex = 0; runIndex < examples.length; runIndex++) {
      final (name, words) = examples[runIndex];
      final note = _generatedNote(runIndex, name, words);

      await tester.pumpWidget(
        hostedPlainly(
          NoteView(
            note: note,
            progress: _folderProgress,
            body: const SizedBox(),
            markRead: () async {},
          ),
        ),
      );

      expect(find.text(note.name), findsOneWidget);
      expect(find.text(readingTimeLabel(note.content)), findsOneWidget);
    }
  });

  testWidgets('NoteView property names what the note was generated from', (
    tester,
  ) async {
    for (final (kind, reference, hasSource) in examplesOf(
      (random) => (
        oneOf(random, ['file', 'link', 'topic', 'text']),
        '${wordOf(random)}.pdf',
        random.nextBool(),
      ),
      runs: 8,
    )) {
      final source = NoteSource(kind: kind, reference: reference);
      final note = Note(
        name: 'Sourced note',
        content: '<p>Some words</p>',
        isRead: false,
        folderId: 'folder',
        source: hasSource ? source : null,
      );
      final readingTime = readingTimeLabel(note.content);

      await tester.pumpWidget(
        hostedPlainly(
          NoteView(
            note: note,
            progress: _folderProgress,
            body: const SizedBox(),
            markRead: () async {},
          ),
        ),
      );

      expect(
        find.text(
          hasSource
              ? '$readingTime · generated from ${source.origin}'
              : readingTime,
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('NoteView property shows the body and the read state', (
    tester,
  ) async {
    for (final (bodyText, isRead) in examplesOf(
      (random) => (wordOf(random), random.nextBool()),
      runs: 6,
    )) {
      final note = _namedNote(
        'Named note',
        '<p>Some words</p>',
        isRead: isRead,
      );

      await tester.pumpWidget(
        hostedPlainly(
          NoteView(
            note: note,
            progress: _folderProgress,
            body: Text('body $bodyText'),
            markRead: () async {},
          ),
        ),
      );

      expect(find.text('body $bodyText'), findsOneWidget);
      expect(
        find.text('Marked as read'),
        isRead ? findsOneWidget : findsNothing,
      );
      expect(find.text('Mark as read'), isRead ? findsNothing : findsOneWidget);
    }
  });

  testWidgets('NoteView property lays the card out like the note CSS', (
    tester,
  ) async {
    for (final (size, bodyHeight, brightness) in examplesOf(
      (random) => (
        Size(
          integerBetween(random, 800, 1800).toDouble(),
          integerBetween(random, 700, 1200).toDouble(),
        ),
        integerBetween(random, 0, 1400).toDouble(),
        oneOf(random, Brightness.values),
      ),
      runs: 12,
    )) {
      _useSurface(tester, size);
      final note = _namedNote('Card note', '<p>x</p>', isRead: false);
      final colors = DesignColors.forBrightness(brightness);
      final shadows = DesignShadows.forBrightness(brightness);

      await tester.pumpWidget(_noteHostedIn(brightness, note, bodyHeight));

      final cardFinder = find
          .ancestor(of: find.text(note.name), matching: find.byType(SurfaceBox))
          .first;
      final card = tester.widget<SurfaceBox>(cardFinder);
      final cardBox = tester.getRect(cardFinder);
      final titleBox = tester.getRect(find.text(note.name));
      final metaBox = tester.getRect(find.text('1 min read'));
      final bodyBox = tester.getRect(find.byKey(_bodyKey));
      final buttonBox = tester.getRect(find.byType(DesignButton));
      final footBox = tester.getRect(find.byType(NoteFoot));
      final expectedWidth = size.width - 2 * 16 < 760
          ? size.width - 2 * 16
          : 760.0;
      final isCardClamped = cardBox.bottom == size.height - _stageInset;

      expect(card.look.fill, colors.surface);
      expect(card.look.border.color, colors.line);
      expect(card.look.shadows, shadows.raised);
      expect(card.borderRadius, 14);
      expect(cardBox.width, expectedWidth);
      expect(cardBox.left, (size.width - expectedWidth) / 2);
      expect(cardBox.top, _stageInset);
      expect(cardBox.bottom, lessThanOrEqualTo(size.height - _stageInset));
      expect(titleBox.left - cardBox.left, _cardInset);
      expect(titleBox.top - cardBox.top, _cardInset);
      expect(metaBox.top - titleBox.bottom, moreOrLessEquals(8));
      expect(bodyBox.top - metaBox.bottom, moreOrLessEquals(33));
      expect(bodyBox.width, expectedWidth - 2 * _cardInset);
      expect(bodyBox.height, isCardClamped ? lessThan(bodyHeight) : bodyHeight);
      expect(buttonBox.top - bodyBox.bottom, moreOrLessEquals(33));
      expect(cardBox.bottom - footBox.bottom, moreOrLessEquals(_cardInset));
    }
  });

  testWidgets('NoteView property sets the title and meta type of the CSS', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final note = _namedNote('Typed note', '', isRead: true);
      final colors = DesignColors.forBrightness(brightness);

      await tester.pumpWidget(_noteHostedIn(brightness, note, 10));

      final title = renderedStyleOf(tester, note.name);
      final meta = renderedStyleOf(tester, 'Generated note');

      expect(title.fontSize, 24);
      expect(title.fontWeight, FontWeight.w600);
      expect(title.letterSpacing, closeTo(0.07 - 0.24, 1e-9));
      expect(meta.fontSize, 14);
      expect(meta.color, colors.inkTertiary);
    }
  });
}
