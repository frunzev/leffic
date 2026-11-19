import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/features/settings/libreoffice_installer.dart';
import 'package:leffic/features/settings/libreoffice_release.dart';
import 'package:leffic/features/settings/libreoffice_setup.dart';

const String _fakeAddress = 'https://download.example.org/LibreOffice.dmg';
const String _copyTool = '/usr/bin/ditto';
const String _attachVerb = 'attach';
const int _mountPointPosition = 5;
const int _copyTargetPosition = 2;
const int _refusedExitCode = 1;

enum ImageStep { attach, copy, detach }

ImageStep stepOf(List<String> command) {
  if (command.first == _copyTool) {
    return ImageStep.copy;
  }

  if (command[1] == _attachVerb) {
    return ImageStep.attach;
  }

  return ImageStep.detach;
}

class FakeImageTools {
  FakeImageTools({this.failingStep});

  ImageStep? failingStep;
  final List<List<String>> commands = [];

  String get attachedMountPoint => commands.first[_mountPointPosition];

  Future<ProcessResult> run(List<String> command, String? input) async {
    commands.add(command);

    final step = stepOf(command);

    if (step == ImageStep.copy) {
      await _startCopyInto(command[_copyTargetPosition]);
    }

    if (step == failingStep) {
      return ProcessResult(0, _refusedExitCode, '', '${step.name} refused');
    }

    if (step == ImageStep.copy) {
      await _finishCopyInto(command[_copyTargetPosition]);
    }

    return ProcessResult(0, 0, '', '');
  }

  Future<void> _startCopyInto(String target) async {
    await File('$target/Contents/Info.plist').create(recursive: true);
  }

  Future<void> _finishCopyInto(String target) async {
    await File('$target/Contents/MacOS/soffice').create(recursive: true);
  }
}

class PacedImageServer {
  PacedImageServer(this.imageBytes);

  final List<int> imageBytes;
  StreamController<List<int>> _chunks = StreamController();

  ReleaseImage get release {
    return ReleaseImage(
      address: _fakeAddress,
      sha256: sha256.convert(imageBytes).toString(),
      bytes: imageBytes.length,
    );
  }

  http.Client client() {
    return MockClient.streaming((request, body) async {
      return http.StreamedResponse(_chunks.stream, HttpStatus.ok);
    });
  }

  void send(int start, int end) => _chunks.add(imageBytes.sublist(start, end));

  Future<void> finish() async {
    final finishedChunks = _chunks;

    _chunks = StreamController();
    await finishedChunks.close();
  }
}

Future<LibreOfficeInstaller> installerServedBy({
  required PacedImageServer server,
  required FakeImageTools tools,
}) async {
  final directory = await Directory.systemTemp.createTemp('libreoffice');

  return LibreOfficeInstaller(
    client: server.client(),
    runCommand: tools.run,
    findDataDirectory: () async => directory,
    release: server.release,
  );
}

class ScriptedLibreOfficeSetup extends ValueNotifier<LibreOfficeState>
    implements LibreOfficeSetup {
  ScriptedLibreOfficeSetup(super.value, {required this.outcome});

  final LibreOfficeState outcome;
  int downloadCount = 0;
  int refreshCount = 0;

  @override
  int get downloadBytes => libreOfficeRelease.bytes;

  @override
  bool get isBusy => false;

  @override
  Future<void> refresh() async {
    refreshCount++;
  }

  @override
  Future<void> download() async {
    downloadCount++;
    value = const LibreOfficeDownloading(0);
    await Future<void>.delayed(Duration.zero);
    value = outcome;
  }

  @override
  Future<void> remove() async {
    value = const LibreOfficeMissing();
  }
}
