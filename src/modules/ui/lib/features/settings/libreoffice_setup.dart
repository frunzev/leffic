import 'package:flutter/foundation.dart';

import 'libreoffice_installer.dart';

const int _wholePercent = 100;
const String _alreadyBusy = 'LibreOffice is being installed already';

sealed class LibreOfficeState {
  const LibreOfficeState();
}

final class LibreOfficeChecking extends LibreOfficeState {
  const LibreOfficeChecking();
}

final class LibreOfficeMissing extends LibreOfficeState {
  const LibreOfficeMissing();
}

final class LibreOfficeDownloading extends LibreOfficeState {
  const LibreOfficeDownloading(this.percent);

  final int percent;
}

final class LibreOfficeInstalling extends LibreOfficeState {
  const LibreOfficeInstalling();
}

final class LibreOfficeInstalled extends LibreOfficeState {
  const LibreOfficeInstalled();
}

final class LibreOfficeFailed extends LibreOfficeState {
  const LibreOfficeFailed(this.reason);

  final String reason;
}

int downloadedPercent(int receivedBytes, int totalBytes) {
  final percent = receivedBytes * _wholePercent ~/ totalBytes;

  return percent.clamp(0, _wholePercent);
}

class LibreOfficeSetup extends ValueNotifier<LibreOfficeState> {
  LibreOfficeSetup(this._installer) : super(const LibreOfficeChecking());

  final LibreOfficeInstaller _installer;

  int get downloadBytes => _installer.release.bytes;

  bool get isBusy {
    return value is LibreOfficeDownloading || value is LibreOfficeInstalling;
  }

  Future<void> refresh() async {
    if (isBusy) {
      return;
    }

    final isInstalled = await _installer.isInstalled();

    if (isBusy) {
      return;
    }

    value = isInstalled
        ? const LibreOfficeInstalled()
        : const LibreOfficeMissing();
  }

  Future<void> download() async {
    _refuseWhileBusy();
    value = const LibreOfficeDownloading(0);

    try {
      await _installer.downloadVerifiedImage(onReceived: _showReceived);
      value = const LibreOfficeInstalling();
      await _installer.installDownloadedImage();
    } on Exception catch (failure) {
      value = LibreOfficeFailed('$failure');
      return;
    }

    value = const LibreOfficeInstalled();
  }

  Future<void> remove() async {
    _refuseWhileBusy();
    await _installer.remove();
    value = const LibreOfficeMissing();
  }

  void _showReceived(int receivedBytes) {
    final percent = downloadedPercent(receivedBytes, downloadBytes);
    final shown = value;

    if (shown is LibreOfficeDownloading && shown.percent == percent) {
      return;
    }

    value = LibreOfficeDownloading(percent);
  }

  void _refuseWhileBusy() {
    if (isBusy) {
      throw StateError(_alreadyBusy);
    }
  }
}
