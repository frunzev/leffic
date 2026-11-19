import 'dart:ui';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';

const String noteHeightChannel = 'NoteHeight';
const int _measureCharacters = 68;
const String _headingLetterSpacing = '0.01em';
const String _fontStack =
    'ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,'
    '"Helvetica Neue",Arial,sans-serif';
const String _heightReporter =
    '<script>new ResizeObserver(function(){$noteHeightChannel.postMessage('
    'String(Math.ceil(document.documentElement.getBoundingClientRect()'
    '.height)))}).observe(document.documentElement)</script>';
const int _rgbMask = 0xFFFFFF;
const int _hexDigits = 6;
const int _hexRadix = 16;

String _hexOf(Color color) {
  final rgb = color.toARGB32() & _rgbMask;

  return '#${rgb.toRadixString(_hexRadix).padLeft(_hexDigits, '0')}';
}

String _pixels(double length) {
  return '${length}px';
}

String _noteStyle(DesignColors colors) {
  final fontSize = _pixels(TextSizes.medium);
  final headingMargin = '${_pixels(Spacing.step5)} 0 ${_pixels(Spacing.step2)}';
  final blockMargin = '0 0 ${_pixels(Spacing.step4)}';

  return '<style>'
      'html{background:${_hexOf(colors.surface)};'
      'color:${_hexOf(colors.ink)};'
      'font:$fontSize/$baseLineHeight $_fontStack;'
      '-webkit-font-smoothing:antialiased}'
      'body{display:flow-root;max-width:${_measureCharacters}ch;margin:0}'
      'h1,h2,h3,h4{margin:$headingMargin;font-size:$fontSize;'
      'font-weight:600;letter-spacing:$_headingLetterSpacing}'
      ':is(h1,h2,h3,h4):first-child{margin-top:0}'
      'p{margin:$blockMargin;color:${_hexOf(colors.inkSecondary)}}'
      'ul,ol{margin:$blockMargin;padding-left:${_pixels(Spacing.step5)};'
      'color:${_hexOf(colors.inkSecondary)}}'
      'li{margin-bottom:${_pixels(Spacing.step1)}}'
      'a{color:${_hexOf(colors.brand)}}'
      '</style>';
}

String noteDocument({required String noteHtml, required DesignColors colors}) {
  return '<!DOCTYPE html><html><head><meta charset="utf-8">'
      '${_noteStyle(colors)}$_heightReporter</head>'
      '<body>$noteHtml</body></html>';
}

double readNoteHeight(String message) {
  final height = double.tryParse(message);

  if (height == null || !height.isFinite || height < 0) {
    throw FormatException('Expected a note height', message);
  }

  return height;
}
