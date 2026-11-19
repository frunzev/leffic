import 'dart:math';

import 'package:leffic/shared/api/json_reading.dart';

import '../../support/property.dart';

const List<String> sourceKinds = ['file', 'link', 'topic', 'text'];

JsonObject generatedSourceJson(Random random) {
  if (random.nextBool()) {
    return const {};
  }

  return {
    'source_kind': oneOf(random, sourceKinds),
    'source_reference': anyTextOf(random),
  };
}

JsonObject generatedNoteJson(Random random) {
  return {
    'name': anyTextOf(random),
    'content': anyTextOf(random, maximum: 200),
    'read': random.nextBool(),
    'folder_id': tokenOf(random),
    ...generatedSourceJson(random),
  };
}

JsonObject generatedNotesStatsJson(Random random) {
  final due = integerBetween(random, 0, 40);
  final read = integerBetween(random, due == 0 ? 1 : 0, 40);

  return {'due': due, 'read': read};
}
