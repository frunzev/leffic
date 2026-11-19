const String _role =
    'You are a memory coach who builds mnemonic devices for learners '
    'revising flashcards in a spaced-repetition app.';

const String _task =
    'Choose the one mnemonic technique that best fits the flashcard below, '
    'then build a single concrete device with it that makes the answer '
    'easy to recall from the question.';

const String _methods =
    '1. Method of Loci (memory palace) — map the items onto a familiar\n'
    '   spatial route. Strongest technique overall; use it when the answer\n'
    '   is an ordered or long set that must be walked through.\n'
    '2. Acronyms and acrostics — first-letter cues such as PEMDAS or HOMES.\n'
    '   Fast and low effort; use it for a handful of items whose initials\n'
    '   form a word or sentence. Weak for long or complex material.\n'
    '3. Chunking — split a large string into meaningful smaller groups that\n'
    '   fit working memory. Use it for numbers, dates and codes.\n'
    '4. Narrative chaining (story-link) — weave the items into a vivid story\n'
    '   where each cues the next. Use it for several linked facts; a broken\n'
    '   link loses the rest of the chain.\n'
    '5. Peg system (pegwords) — hang the items on a pre-memorised peg list\n'
    '   so any one can be recalled directly. Use it when random access to a\n'
    '   numbered list matters.\n'
    '6. Keyword method — bridge an unfamiliar word to a similar-sounding\n'
    '   familiar word and picture the two together. Use it for vocabulary,\n'
    '   terminology and foreign-language cards.';

const String _constraints =
    "- Pick exactly one technique and name it. Match it to the card's shape:\n"
    '  ordered set to loci or pegwords, few initials to an acronym, long\n'
    '  number to chunking, term or vocabulary to the keyword method,\n'
    '  several linked facts to a story.\n'
    '- Build the device only from what the card states. Invent no facts and\n'
    '  do not correct the card.\n'
    '- Make the imagery concrete, sensory and a little absurd — abstractions\n'
    '  are not memorable.\n'
    '- Stay under 120 words. No preamble, no apology, no markdown headings.';

const String _output =
    'Plain text, exactly three short labelled parts:\n'
    'Technique: the name, plus one clause on why it fits this card.\n'
    'Device: the mnemonic itself, spelled out.\n'
    'Recall: one or two sentences mapping the device back to the answer.';

const String _titleStart = 'Mnemonic for: ';
const String _cutMarker = '…';
const int _shownQuestionLimit = 60;

String mnemonicPrompt({required String question, required String answer}) {
  final context =
      'CONTEXT\nFlashcard question: $question\nFlashcard answer: $answer\n\n'
      'Mnemonic techniques, strongest first:\n$_methods';
  final sections = [
    'ROLE\n$_role',
    'TASK\n$_task',
    context,
    'CONSTRAINTS\n$_constraints',
    'OUTPUT\n$_output',
  ];

  return sections.join('\n\n');
}

String mnemonicTitle(String question) {
  final asked = question.trim();

  if (asked.length <= _shownQuestionLimit) {
    return '$_titleStart$asked';
  }

  final shown = asked.substring(0, _shownQuestionLimit).trimRight();

  return '$_titleStart$shown$_cutMarker';
}
