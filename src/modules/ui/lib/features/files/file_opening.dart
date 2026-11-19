import 'dart:io';

import '../../shared/navigation/routes.dart';
import 'file_models.dart';
import 'files_api.dart';

typedef TemporaryDirectoryFinder = Future<Directory> Function();

const String _pdfExtension = 'pdf';

Future<OpenedFile> openFile({
  required FilesApi api,
  required FileArguments file,
  required TemporaryDirectoryFinder findTemporaryDirectory,
}) async {
  final details = await api.readFileDetails(file.id);
  final pdfBytes = await api.fetchPdf(file);
  final temporaryDirectory = await findTemporaryDirectory();
  final pdf = File('${temporaryDirectory.path}/${file.id}.$_pdfExtension');

  await temporaryDirectory.create(recursive: true);
  await pdf.writeAsBytes(pdfBytes);

  return OpenedFile(pdf: pdf, details: details);
}
