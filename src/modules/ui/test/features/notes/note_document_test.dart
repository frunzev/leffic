import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_document.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/property.dart';

String _hexOf(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;

  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

void main() {
  test('noteDocument property wraps the note in one whole HTML page', () {
    forAll(
      (random) =>
          (anyTextOf(random, maximum: 300), oneOf(random, Brightness.values)),
      (example) {
        final (noteHtml, brightness) = example;
        final document = noteDocument(
          noteHtml: noteHtml,
          colors: DesignColors.forBrightness(brightness),
        );

        expect(document, startsWith('<!DOCTYPE html>'));
        expect(document, endsWith('</html>'));
        expect(document, contains('<body>$noteHtml</body>'));
      },
    );
  });

  test('noteDocument property paints the note in the theme colours', () {
    for (final brightness in Brightness.values) {
      final colors = DesignColors.forBrightness(brightness);
      final document = noteDocument(noteHtml: '<p>note</p>', colors: colors);

      expect(document, contains('background:${_hexOf(colors.surface)}'));
      expect(document, contains('color:${_hexOf(colors.ink)}'));
      expect(document, contains('color:${_hexOf(colors.inkSecondary)}'));
      expect(document, contains('color:${_hexOf(colors.brand)}'));
    }
  });

  test('noteDocument property sets the design paper typography', () {
    forAll((random) => oneOf(random, Brightness.values), (brightness) {
      final document = noteDocument(
        noteHtml: '',
        colors: DesignColors.forBrightness(brightness),
      );

      expect(document, contains('font:16.0px/1.55 ui-sans-serif'));
      expect(document, contains('max-width:68ch'));
      expect(document, contains('margin:24.0px 0 8.0px'));
      expect(document, contains('letter-spacing:0.01em'));
      expect(document, contains('padding-left:24.0px'));
    }, runs: 4);
  });

  test('noteDocument property reports its height on the height channel', () {
    final document = noteDocument(
      noteHtml: '<p>note</p>',
      colors: DesignColors.forBrightness(Brightness.light),
    );

    expect(document, contains('$noteHeightChannel.postMessage'));
    expect(document, contains('ResizeObserver'));
  });

  test('readNoteHeight property reads back every height it is sent', () {
    forAll((random) => integerBetween(random, 0, 100000) / 4, (height) {
      expect(readNoteHeight('$height'), height);
    });
  });

  test('readNoteHeight property refuses what is not a height', () {
    forAll(
      (random) => oneOf(random, [
        wordOf(random),
        '-${integerBetween(random, 1, 5000)}',
        'NaN',
        'Infinity',
        '',
      ]),
      (message) {
        expect(() => readNoteHeight(message), throwsFormatException);
      },
    );
  });
}
