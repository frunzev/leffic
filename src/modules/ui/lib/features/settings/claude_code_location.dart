import 'dart:io';

import '../../shared/backend/backend_environment.dart';

const String _executableName = 'claude';
const String _pathSeparator = ':';
const String _homeVariable = 'HOME';
const String _systemWideLocation = '/usr/local/bin/claude';
const String _missingHome = 'HOME is not set, so Claude Code cannot be found';
const List<String> _homeLocationsBeforeSystem = ['.npm-global/bin/claude'];
const List<String> _homeLocationsAfterSystem = [
  '.local/bin/claude',
  'node_modules/.bin/claude',
  '.yarn/bin/claude',
  '.claude/local/claude',
];

List<String> claudeCodeCandidates({
  required String searchPath,
  required String homeDirectory,
}) {
  final candidates = <String>[];

  for (final directory in searchPath.split(_pathSeparator)) {
    if (directory.isNotEmpty) {
      candidates.add('$directory/$_executableName');
    }
  }

  for (final location in _homeLocationsBeforeSystem) {
    candidates.add('$homeDirectory/$location');
  }

  candidates.add(_systemWideLocation);

  for (final location in _homeLocationsAfterSystem) {
    candidates.add('$homeDirectory/$location');
  }

  return candidates;
}

Future<String?> findClaudeCode(List<String> candidates) async {
  for (final candidate in candidates) {
    if (await File(candidate).exists()) {
      return candidate;
    }
  }

  return null;
}

Future<String?> findInstalledClaudeCode() {
  final homeDirectory = Platform.environment[_homeVariable];

  if (homeDirectory == null) {
    throw StateError(_missingHome);
  }

  final candidates = claudeCodeCandidates(
    searchPath: backendToolSearchPath,
    homeDirectory: homeDirectory,
  );

  return findClaudeCode(candidates);
}
