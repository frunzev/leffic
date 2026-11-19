import 'dart:convert';
import 'dart:io';

import '../../shared/api/json_reading.dart';
import 'progress_memory.dart';
import 'test_position.dart';

typedef DirectoryLocator = Future<Directory> Function();

const String _progressFileName = 'test-progress.json';

class FileProgressMemory implements ProgressMemory {
  const FileProgressMemory({
    required this.scopeId,
    required this.locateDirectory,
  });

  final String scopeId;
  final DirectoryLocator locateDirectory;

  @override
  Future<TestPosition> recall() async {
    final positions = await _storedPositions();

    if (positions[scopeId] == null) {
      return TestPosition.start;
    }

    return TestPosition.fromJson(readObject(positions, scopeId));
  }

  @override
  Future<void> remember(TestPosition position) async {
    final positions = await _storedPositions();

    await _store({...positions, scopeId: position.toJson()});
  }

  @override
  Future<void> forget() async {
    final positions = await _storedPositions();
    final remaining = Map.of(positions)..remove(scopeId);

    await _store(remaining);
  }

  Future<File> _progressFile() async {
    final directory = await locateDirectory();

    return File('${directory.path}/$_progressFileName');
  }

  Future<JsonObject> _storedPositions() async {
    final file = await _progressFile();

    if (!file.existsSync()) {
      return const {};
    }

    return asObject(jsonDecode(file.readAsStringSync()));
  }

  Future<void> _store(JsonObject positions) async {
    final file = await _progressFile();

    file.writeAsStringSync(jsonEncode(positions));
  }
}
