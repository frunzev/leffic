const String _applicationName = 'LibreOffice.app';
const String _stagedApplicationName = 'LibreOffice.app.partial';
const String _binaryInsideApplication = 'Contents/MacOS/soffice';
const String _imageName = 'LibreOffice-download.dmg';

class LibreOfficeLayout {
  const LibreOfficeLayout(this.dataDirectory);

  final String dataDirectory;

  String get application => '$dataDirectory/$_applicationName';

  String get stagedApplication => '$dataDirectory/$_stagedApplicationName';

  String get binary => '$application/$_binaryInsideApplication';

  String get image => '$dataDirectory/$_imageName';
}
