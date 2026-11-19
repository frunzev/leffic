import 'dart:math';

typedef Generator<T> = T Function(Random random);

const int defaultRuns = 100;
const int defaultExampleRuns = 30;
const int fixedSeed = 20261118;
const String _letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _digits = '0123456789';

void forAll<T>(
  Generator<T> generator,
  void Function(T example) check, {
  int runs = defaultRuns,
}) {
  final random = Random(fixedSeed);

  for (var run = 0; run < runs; run++) {
    check(generator(random));
  }
}

List<T> examplesOf<T>(Generator<T> generator, {int runs = defaultExampleRuns}) {
  final examples = <T>[];

  forAll(generator, examples.add, runs: runs);

  return examples;
}

int integerBetween(Random random, int lowest, int highest) {
  return lowest + random.nextInt(highest - lowest + 1);
}

String textFrom(Random random, String alphabet, int minimum, int maximum) {
  final length = integerBetween(random, minimum, maximum);
  final buffer = StringBuffer();

  for (var index = 0; index < length; index++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }

  return buffer.toString();
}

String wordOf(Random random, {int minimum = 1, int maximum = 16}) {
  return textFrom(random, _letters, minimum, maximum);
}

String tokenOf(Random random, {int minimum = 1, int maximum = 40}) {
  return textFrom(random, '$_letters${_digits}_-', minimum, maximum);
}

String anyTextOf(Random random, {int maximum = 40}) {
  final length = integerBetween(random, 0, maximum);
  final codeUnits = <int>[];

  for (var index = 0; index < length; index++) {
    codeUnits.add(integerBetween(random, 32, 0x2FFF));
  }

  return String.fromCharCodes(codeUnits);
}

T oneOf<T>(Random random, List<T> choices) {
  return choices[random.nextInt(choices.length)];
}
