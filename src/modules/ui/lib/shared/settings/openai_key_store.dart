import 'dart:io';

typedef CommandRunner = Future<ProcessResult> Function(
  List<String> command,
  String? input,
);

const String _securityTool = '/usr/bin/security';
const String _service = 'leffic-openai-api-key';
const String _account = 'leffic';
const List<String> _itemArguments = ['-s', _service, '-a', _account];
const int _itemNotFound = 44;
final RegExp _keyCharacters = RegExp(r'^[A-Za-z0-9_-]+$');

class KeychainError implements Exception {
  const KeychainError(this.message);

  final String message;

  @override
  String toString() => message;
}

bool isStorableApiKey(String key) => _keyCharacters.hasMatch(key);

class OpenAiKeyStore {
  const OpenAiKeyStore(this._run);

  final CommandRunner _run;

  Future<String?> readKey() async {
    final result = await _run([
      _securityTool,
      'find-generic-password',
      ..._itemArguments,
      '-w',
    ], null);

    if (result.exitCode == _itemNotFound) {
      return null;
    }

    if (result.exitCode != 0) {
      throw KeychainError('The keychain refused to read: ${result.stderr}');
    }

    return '${result.stdout}'.trim();
  }

  Future<void> saveKey(String key) async {
    if (!isStorableApiKey(key)) {
      throw ArgumentError.value(key, 'key', 'is not an API key');
    }

    final command =
        'add-generic-password -U -s $_service -a $_account -w "$key"\n';
    final result = await _run([_securityTool, '-i'], command);

    if (result.exitCode != 0) {
      throw KeychainError('The keychain refused to save: ${result.stderr}');
    }
  }

  Future<void> deleteKey() async {
    final result = await _run([
      _securityTool,
      'delete-generic-password',
      ..._itemArguments,
    ], null);

    if (result.exitCode == 0 || result.exitCode == _itemNotFound) {
      return;
    }

    throw KeychainError('The keychain refused to remove: ${result.stderr}');
  }
}

Future<ProcessResult> runCommand(List<String> command, String? input) async {
  final process = await Process.start(command.first, command.sublist(1));

  if (input != null) {
    process.stdin.write(input);
  }

  await process.stdin.close();

  final output = await process.stdout.transform(systemEncoding.decoder).join();
  final errors = await process.stderr.transform(systemEncoding.decoder).join();
  final exitCode = await process.exitCode;

  return ProcessResult(process.pid, exitCode, output, errors);
}
