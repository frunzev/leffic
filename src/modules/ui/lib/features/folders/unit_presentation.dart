import '../../shared/design/icons/design_icons.dart';
import 'folder_models.dart';
import 'unit_details.dart';

const String _metaSeparator = ' · ';
const String _itemNoun = 'item';
const String _cardNoun = 'card';
const String _questionNoun = 'question';
const String _extensionlessFileKind = 'File';
const int _bytesPerKilobyte = 1000;
const int _bytesPerMegabyte = 1000000;
const int _sizeDecimals = 1;

DesignIcons iconForUnitType(UnitType type) {
  return switch (type) {
    UnitType.folder => DesignIcons.folder,
    UnitType.flashcardDeck => DesignIcons.flashcards,
    UnitType.test => DesignIcons.test,
    UnitType.note => DesignIcons.note,
    UnitType.file => DesignIcons.file,
  };
}

String unitNoun(UnitType type) {
  return switch (type) {
    UnitType.folder => 'folder',
    UnitType.flashcardDeck => 'deck',
    UnitType.test => 'test',
    UnitType.note => 'note',
    UnitType.file => 'file',
  };
}

String countLabel({required int count, required String noun}) {
  if (count == 1) {
    return '1 $noun';
  }

  return '$count ${noun}s';
}

String itemCountLabel(int count) {
  return countLabel(count: count, noun: _itemNoun);
}

String fileSizeLabel(int sizeBytes) {
  if (sizeBytes < _bytesPerMegabyte) {
    final kilobytes = sizeBytes / _bytesPerKilobyte;

    return '${kilobytes.toStringAsFixed(_sizeDecimals)} KB';
  }

  final megabytes = sizeBytes / _bytesPerMegabyte;

  return '${megabytes.toStringAsFixed(_sizeDecimals)} MB';
}

String dueBadgeLabel(int dueCount) {
  return '$dueCount due';
}

DateTime _calendarDayOf(DateTime moment) {
  final local = moment.toLocal();

  return DateTime.utc(local.year, local.month, local.day);
}

String describeAge({required DateTime moment, required DateTime now}) {
  final momentDay = _calendarDayOf(moment);
  final today = _calendarDayOf(now);
  final days = today.difference(momentDay).inDays;

  if (days <= 0) {
    return 'today';
  }

  if (days == 1) {
    return 'yesterday';
  }

  return '$days days ago';
}

String _fileKind(String extension) {
  if (extension.isEmpty) {
    return _extensionlessFileKind;
  }

  return extension.toUpperCase();
}

String _fileMetaLine(String extension, int? sizeBytes) {
  final kind = _fileKind(extension);

  if (sizeBytes == null) {
    return kind;
  }

  return '$kind$_metaSeparator${fileSizeLabel(sizeBytes)}';
}

String _folderMetaLine(FolderDetails details, DateTime now) {
  final items = itemCountLabel(details.itemCount);
  final age = describeAge(moment: details.editedAt, now: now);

  return '$items${_metaSeparator}edited $age';
}

String unitMetaLine({required FolderUnit unit, required DateTime now}) {
  final details = unit.details;

  return switch (details) {
    FolderDetails() => _folderMetaLine(details, now),
    DeckDetails() => countLabel(count: details.cardCount, noun: _cardNoun),
    TestDetails() => countLabel(
      count: details.questionCount,
      noun: _questionNoun,
    ),
    NoteDetails() => '${details.readingMinutes} min read',
    FileDetails() => _fileMetaLine(unit.extension, details.sizeBytes),
  };
}

int unitDueCount(FolderUnit unit) {
  return switch (unit.details) {
    DeckDetails(:final dueCount) => dueCount,
    TestDetails(:final dueCount) => dueCount,
    FolderDetails() || NoteDetails() || FileDetails() => 0,
  };
}
