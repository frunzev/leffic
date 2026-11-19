class LibreOfficeSetupError implements Exception {
  const LibreOfficeSetupError(this.message);

  final String message;

  @override
  String toString() => message;
}
