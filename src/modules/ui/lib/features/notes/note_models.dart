import '../../shared/api/json_reading.dart';

const String _readKey = 'read';
const String _sourceKindKey = 'source_kind';
const String _pastedTextSourceKind = 'text';
const String _pastedTextOrigin = 'your text';

bool _readStateOf(JsonObject json) {
  final readState = json[_readKey];

  if (readState is bool) {
    return readState;
  }

  throw const FormatException('Expected true or false at "$_readKey"');
}

NoteSource? _sourceOf(JsonObject json) {
  if (json[_sourceKindKey] == null) {
    return null;
  }

  return NoteSource(
    kind: readText(json, _sourceKindKey),
    reference: readText(json, 'source_reference'),
  );
}

class NoteSource {
  const NoteSource({required this.kind, required this.reference});

  final String kind;
  final String reference;

  String get origin {
    if (kind == _pastedTextSourceKind) {
      return _pastedTextOrigin;
    }

    return reference;
  }
}

class Note {
  const Note({
    required this.name,
    required this.content,
    required this.isRead,
    required this.folderId,
    required this.source,
  });

  factory Note.fromJson(JsonObject json) {
    return Note(
      name: readText(json, 'name'),
      content: readText(json, 'content'),
      isRead: _readStateOf(json),
      folderId: readText(json, 'folder_id'),
      source: _sourceOf(json),
    );
  }

  final String name;
  final String content;
  final bool isRead;
  final String folderId;
  final NoteSource? source;
}

class NotesProgress {
  const NotesProgress({required this.read, required this.total});

  factory NotesProgress.fromJson(JsonObject json) {
    final read = readWholeNumber(json, 'read');
    final due = readWholeNumber(json, 'due');

    return NotesProgress(read: read, total: read + due);
  }

  final int read;
  final int total;

  NotesProgress afterOneMoreRead() {
    return NotesProgress(read: read + 1, total: total);
  }
}
