import 'dart:math';

double computeCompletedShare({required int done, required int total}) {
  if (total == 0) {
    return 0;
  }

  return min(1, done / total);
}

int countRemaining({required int done, required int total}) {
  return max(0, total - done);
}
