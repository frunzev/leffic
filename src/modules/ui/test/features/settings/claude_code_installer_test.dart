import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/claude_code_installer.dart';

import '../../support/property.dart';

class _RecordingShell {
  _RecordingShell({required this.exitCode, required this.errors});

  final int exitCode;
  final String errors;
  final List<List<String>> commands = [];

  Future<ProcessResult> run(List<String> command, String? input) async {
    commands.add(command);

    return ProcessResult(0, exitCode, '', errors);
  }
}

void main() {
  test('installClaudeCode property runs only the official installer', () async {
    for (final errors in examplesOf(anyTextOf)) {
      final shell = _RecordingShell(exitCode: 0, errors: errors);

      await installClaudeCode(shell.run);

      expect(shell.commands, [
        [
          '/bin/bash',
          '-c',
          'set -o pipefail; curl -fsSL https://claude.ai/install.sh | bash',
        ],
      ]);
    }
  });

  test('installClaudeCode property reports why the installer failed', () async {
    for (final (exitCode, errors) in examplesOf(
      (random) => (integerBetween(random, 1, 255), 'Error ${wordOf(random)}'),
    )) {
      final shell = _RecordingShell(exitCode: exitCode, errors: errors);

      await expectLater(
        installClaudeCode(shell.run),
        throwsA(
          isA<ClaudeCodeInstallError>().having(
            (refusal) => refusal.message,
            'message',
            contains(errors),
          ),
        ),
      );
    }
  });
}
