const int _shownStartLength = 3;
const int _shownEndLength = 4;
const int _shortestPartlyShownKey =
    2 * (_shownStartLength + _shownEndLength) + 1;
const String _hiddenPart = '…';

String maskApiKey(String key) {
  if (key.length < _shortestPartlyShownKey) {
    return _hiddenPart;
  }

  final shownStart = key.substring(0, _shownStartLength);
  final shownEnd = key.substring(key.length - _shownEndLength);

  return '$shownStart$_hiddenPart$shownEnd';
}
