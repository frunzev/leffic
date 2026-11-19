import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/claude_code_location.dart';

import '../../support/property.dart';

const List<String> _homeFallbacks = [
  '.npm-global/bin/claude',
  '.local/bin/claude',
  'node_modules/.bin/claude',
  '.yarn/bin/claude',
  '.claude/local/claude',
];

List<String> _directoriesOf(Random random) {
  final count = integerBetween(random, 0, 6);

  return [for (var index = 0; index < count; index++) '/${wordOf(random)}'];
}

void main() {
  test('claudeCodeCandidates property searches PATH before the home', () {
    forAll((random) => (_directoriesOf(random), '/Users/${wordOf(random)}'), (
      example,
    ) {
      final (directories, home) = example;
      final searchPath = ['', ...directories, ''].join(':');
      final candidates = claudeCodeCandidates(
        searchPath: searchPath,
        homeDirectory: home,
      );
      final onPath = [for (final directory in directories) '$directory/claude'];

      expect(candidates.sublist(0, onPath.length), onPath);
      expect(candidates, contains('$home/.local/bin/claude'));
      expect(candidates, contains('/usr/local/bin/claude'));

      for (final fallback in _homeFallbacks) {
        expect(
          candidates.indexOf('$home/$fallback'),
          greaterThanOrEqualTo(onPath.length),
        );
      }

      for (final candidate in candidates) {
        expect(candidate, endsWith('/claude'));
        expect(candidate, startsWith('/'));
      }
    });
  });

  test('findClaudeCode property returns the first file that exists', () async {
    for (final (candidateCount, presentMask) in examplesOf(
      (random) => (integerBetween(random, 1, 6), random.nextInt(64)),
    )) {
      final directory = await Directory.systemTemp.createTemp('claude');
      final candidates = [
        for (var index = 0; index < candidateCount; index++)
          '${directory.path}/place$index/claude',
      ];
      String? expected;

      for (var index = 0; index < candidateCount; index++) {
        if (presentMask & (1 << index) == 0) {
          continue;
        }

        await File(candidates[index]).create(recursive: true);
        expected ??= candidates[index];
      }

      expect(await findClaudeCode(candidates), expected);
    }
  });

  test('findInstalledClaudeCode property names an existing claude', () async {
    final found = await findInstalledClaudeCode();

    if (found != null) {
      expect(found, endsWith('/claude'));
      expect(await File(found).exists(), isTrue);
    }
  });
}
