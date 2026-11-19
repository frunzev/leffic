import 'dart:math';
import 'dart:typed_data';

import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/import/amount_choice.dart';
import 'package:leffic/shared/import/generation_choices.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/property.dart';

const List<String> unpagedExtensions = ['txt', 'csv', 'png', 'mp3', 'html'];

UploadedFile generatedFile(Random random, String extension) {
  return UploadedFile(
    name: '${wordOf(random)}.$extension',
    bytes: Uint8List.fromList(tokenOf(random).codeUnits),
  );
}

PageSelection generatedPages(Random random) {
  return PageSelection(
    first: oneOf(random, [null, integerBetween(random, 1, 20)]),
    last: oneOf(random, [null, integerBetween(random, 21, 90)]),
  );
}

ImportSource generatedSource(Random random) {
  return switch (random.nextInt(5)) {
    0 => FileImportSource(
      file: generatedFile(random, oneOf(random, pagedExtensions)),
      pages: generatedPages(random),
    ),
    1 => LinkImportSource(address: 'https://${wordOf(random)}.org'),
    2 => PastedTextImportSource(text: 'Pasted ${wordOf(random)}'),
    3 => StoredFileImportSource(
      fileId: tokenOf(random),
      fileName: '${wordOf(random)}.pdf',
    ),
    _ => TopicImportSource(topic: wordOf(random)),
  };
}

AmountChoice generatedAmountChoice(Random random) {
  return AmountChoice(
    mode: oneOf(random, AmountMode.values),
    customAmount: oneOf(random, [null, integerBetween(random, 1, 60)]),
  );
}

GeneratedSetChoice generatedSetChoice(
  Random random,
  List<StudyUnitTypeOption> options,
) {
  return GeneratedSetChoice(
    isChosen: random.nextBool(),
    chosenTypeIds: [
      for (final option in options)
        if (random.nextBool()) option.id,
    ],
    amountChoices: {
      for (final option in options)
        if (random.nextBool()) option.id: generatedAmountChoice(random),
    },
  );
}

GenerationChoices generatedChoices(Random random) {
  return GenerationChoices(
    flashcards: generatedSetChoice(random, flashcardTypeOptions),
    test: generatedSetChoice(random, testTypeOptions),
    isNoteChosen: random.nextBool(),
  );
}
