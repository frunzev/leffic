class ClozePiece {
  const ClozePiece({required this.text, required this.isHidden});

  final String text;
  final bool isHidden;
}

List<ClozePiece> clozePieces({
  required String text,
  required List<String> hiddenParts,
}) {
  var pieces = [ClozePiece(text: text, isHidden: false)];

  for (final hiddenPart in hiddenParts) {
    if (hiddenPart.isNotEmpty) {
      pieces = _hideEverywhere(pieces, hiddenPart);
    }
  }

  final shownPieces = <ClozePiece>[];

  for (final piece in pieces) {
    if (piece.text.isNotEmpty) {
      shownPieces.add(piece);
    }
  }

  return shownPieces;
}

List<ClozePiece> _hideEverywhere(List<ClozePiece> pieces, String hiddenPart) {
  final split = <ClozePiece>[];

  for (final piece in pieces) {
    if (piece.isHidden) {
      split.add(piece);
    } else {
      split.addAll(_hideInside(piece.text, hiddenPart));
    }
  }

  return split;
}

List<ClozePiece> _hideInside(String text, String hiddenPart) {
  final visibleParts = text.split(hiddenPart);
  final pieces = <ClozePiece>[];

  for (var index = 0; index < visibleParts.length; index++) {
    if (index > 0) {
      pieces.add(ClozePiece(text: hiddenPart, isHidden: true));
    }

    pieces.add(ClozePiece(text: visibleParts[index], isHidden: false));
  }

  return pieces;
}
