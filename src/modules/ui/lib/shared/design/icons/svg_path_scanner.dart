final RegExp _numberPattern = RegExp(r'[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?');
const String _separators = ' \t\n\r\f,';
const String _numberStarts = '+-.0123456789';
const String _commandLetters = 'MmLlHhVvCcQqTtAaZz';
const String _raisedFlag = '1';
const String _flags = '01';

class SvgPathScanner {
  SvgPathScanner(this._source) {
    _skipSeparators();
  }

  final String _source;
  int _position = 0;

  bool get isFinished => _position >= _source.length;

  bool get isNumberNext {
    return !isFinished && _numberStarts.contains(_source[_position]);
  }

  String readCommandLetter() {
    _requireNext(_commandLetters, 'a path command');

    return _takeCharacter();
  }

  double readNumber() {
    final match = _numberPattern.matchAsPrefix(_source, _position);

    if (match == null) {
      throw _failureExpecting('a number');
    }

    final digits = _source.substring(match.start, match.end);

    _position = match.end;
    _skipSeparators();

    return double.parse(digits);
  }

  bool readFlag() {
    _requireNext(_flags, 'an arc flag of 0 or 1');

    return _takeCharacter() == _raisedFlag;
  }

  void _requireNext(String allowedCharacters, String expectation) {
    if (isFinished || !allowedCharacters.contains(_source[_position])) {
      throw _failureExpecting(expectation);
    }
  }

  String _takeCharacter() {
    final character = _source[_position];

    _position++;
    _skipSeparators();

    return character;
  }

  void _skipSeparators() {
    while (!isFinished && _separators.contains(_source[_position])) {
      _position++;
    }
  }

  FormatException _failureExpecting(String expectation) {
    return FormatException(
      'SVG path data needs $expectation here',
      _source,
      _position,
    );
  }
}
