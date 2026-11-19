import 'package:leffic/features/assessment/progress_memory.dart';
import 'package:leffic/features/assessment/test_position.dart';

class RememberedProgress implements ProgressMemory {
  RememberedProgress(this.position);

  TestPosition? position;
  final List<TestPosition?> history = [];

  @override
  Future<TestPosition> recall() async => position ?? TestPosition.start;

  @override
  Future<void> remember(TestPosition remembered) async {
    position = remembered;
    history.add(remembered);
  }

  @override
  Future<void> forget() async {
    position = null;
    history.add(null);
  }
}
