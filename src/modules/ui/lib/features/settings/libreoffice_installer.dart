import 'dart:io';

import 'package:http/http.dart' as http;

import '../../shared/backend/libreoffice_layout.dart';
import '../../shared/settings/openai_key_store.dart' show CommandRunner;
import 'file_download.dart';
import 'image_checksum.dart';
import 'libreoffice_release.dart';
import 'libreoffice_setup_error.dart';

const String _imageTool = '/usr/bin/hdiutil';
const String _copyTool = '/usr/bin/ditto';
const String _mountPointPrefix = 'leffic-libreoffice-image';
const String _applicationInsideImage = 'LibreOffice.app';

class LibreOfficeInstaller {
  const LibreOfficeInstaller({
    required this.client,
    required this.runCommand,
    required this.findDataDirectory,
    required this.release,
  });

  final http.Client client;
  final CommandRunner runCommand;
  final Future<Directory> Function() findDataDirectory;
  final ReleaseImage release;

  Future<bool> isInstalled() async {
    final layout = await _layout();

    return File(layout.binary).exists();
  }

  Future<void> downloadVerifiedImage({
    required ReceivedBytesListener onReceived,
  }) async {
    final layout = await _layout();
    final image = File(layout.image);

    try {
      await downloadToFile(
        client: client,
        address: Uri.parse(release.address),
        destination: image,
        onReceived: onReceived,
      );
      await refuseUnlessSha256Matches(
        file: image,
        expectedSha256: release.sha256,
      );
    } on Exception {
      await _deleteIfPresent(image);
      rethrow;
    }
  }

  Future<void> installDownloadedImage() async {
    final layout = await _layout();
    final image = File(layout.image);

    try {
      await _copyApplicationOutOf(image, layout);
    } finally {
      await _deleteIfPresent(image);
    }
  }

  Future<void> remove() async {
    final layout = await _layout();

    await _deleteIfPresent(Directory(layout.application));
  }

  Future<LibreOfficeLayout> _layout() async {
    final dataDirectory = await findDataDirectory();

    return LibreOfficeLayout(dataDirectory.path);
  }

  Future<void> _copyApplicationOutOf(
    File image,
    LibreOfficeLayout layout,
  ) async {
    final staged = Directory(layout.stagedApplication);

    await _deleteIfPresent(staged);

    try {
      await _copyMountedApplication(image, staged);
    } on Exception {
      await _deleteIfPresent(staged);
      rethrow;
    }

    await _deleteIfPresent(Directory(layout.application));
    await staged.rename(layout.application);
  }

  Future<void> _copyMountedApplication(File image, Directory staged) async {
    final mountPoint = await Directory.systemTemp.createTemp(_mountPointPrefix);
    final mountedApplication = '${mountPoint.path}/$_applicationInsideImage';

    await _run([
      _imageTool,
      'attach',
      '-nobrowse',
      '-readonly',
      '-mountpoint',
      mountPoint.path,
      image.path,
    ]);

    try {
      await _run([_copyTool, mountedApplication, staged.path]);
    } finally {
      await _run([_imageTool, 'detach', mountPoint.path]);
    }

    await mountPoint.delete();
  }

  Future<void> _run(List<String> command) async {
    final result = await runCommand(command, null);

    if (result.exitCode != 0) {
      throw LibreOfficeSetupError('${command.first} failed: ${result.stderr}');
    }
  }
}

Future<void> _deleteIfPresent(FileSystemEntity entity) async {
  if (await entity.exists()) {
    await entity.delete(recursive: true);
  }
}
