import 'progress_memory.dart';
import 'test_position.dart';

class UnsavedProgress implements ProgressMemory {
  const UnsavedProgress();

  @override
  Future<TestPosition> recall() async => TestPosition.start;

  @override
  Future<void> remember(TestPosition position) async {}

  @override
  Future<void> forget() async {}
}
