import 'test_position.dart';

abstract interface class ProgressMemory {
  Future<TestPosition> recall();

  Future<void> remember(TestPosition position);

  Future<void> forget();
}
