import '../../shared/settings/openai_key_store.dart' show CommandRunner;

const List<String> _officialInstaller = [
  '/bin/bash',
  '-c',
  'set -o pipefail; curl -fsSL https://claude.ai/install.sh | bash',
];

class ClaudeCodeInstallError implements Exception {
  const ClaudeCodeInstallError(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<void> installClaudeCode(CommandRunner runCommand) async {
  final result = await runCommand(_officialInstaller, null);

  if (result.exitCode != 0) {
    throw ClaudeCodeInstallError(
      'The Claude Code installer failed: ${result.stderr}',
    );
  }
}
