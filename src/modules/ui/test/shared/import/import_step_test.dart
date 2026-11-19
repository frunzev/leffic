import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/import_step.dart';

import '../../support/property.dart';
import 'import_fakes.dart';

void main() {
  test('firstImportStep property reads a given source before anything', () {
    forAll(generatedSource, (source) {
      final step = firstImportStep(source);

      expect(step, isA<ReadingSource>());
      expect((step as ReadingSource).source, same(source));
      expect(firstImportStep(null), isA<ChoosingSource>());
    });
  });
}
