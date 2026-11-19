import 'dart:io';

const Duration _retryPause = Duration(milliseconds: 100);

class BackendStartError implements Exception {
  const BackendStartError(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackendCommand {
  const BackendCommand({required this.executable, required this.arguments});

  final String executable;
  final List<String> arguments;
}

class RunningBackend {
  const RunningBackend(this._process);

  final Process _process;

  Future<int> get exitCode => _process.exitCode;

  Future<void> stop() async {
    _process.kill();

    await _process.exitCode;
  }
}

Future<RunningBackend> startBackend({
  required BackendCommand command,
  required Map<String, String> environment,
  required Directory dataDirectory,
  required int port,
  required Duration patience,
}) async {
  final process = await Process.start(
    command.executable,
    command.arguments,
    environment: environment,
    workingDirectory: dataDirectory.path,
  );
  final backend = RunningBackend(process);

  try {
    await waitUntilListening(port, patience);
  } on BackendStartError {
    await backend.stop();
    rethrow;
  }

  return backend;
}

Future<void> waitUntilListening(int port, Duration patience) async {
  final deadline = DateTime.now().add(patience);

  while (DateTime.now().isBefore(deadline)) {
    if (await _accepts(port)) {
      return;
    }

    await Future<void>.delayed(_retryPause);
  }

  throw BackendStartError('The backend did not start on port $port');
}

Future<bool> _accepts(int port) async {
  try {
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    await socket.close();

    return true;
  } on SocketException {
    return false;
  }
}
