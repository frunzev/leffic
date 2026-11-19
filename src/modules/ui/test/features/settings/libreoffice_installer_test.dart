import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/features/settings/libreoffice_installer.dart';
import 'package:leffic/features/settings/libreoffice_release.dart';
import 'package:leffic/features/settings/libreoffice_setup_error.dart';
import 'package:leffic/shared/backend/libreoffice_layout.dart';

import '../../support/property.dart';
import 'libreoffice_fakes.dart';

const String _address = 'https://download.example.org/LibreOffice.dmg';

List<int> _imageBytesOf(Random random) {
  final length = integerBetween(random, 1, 2048);

  return [for (var index = 0; index < length; index++) random.nextInt(256)];
}

ReleaseImage _releaseOf(List<int> imageBytes) {
  return ReleaseImage(
    address: _address,
    sha256: sha256.convert(imageBytes).toString(),
    bytes: imageBytes.length,
  );
}

http.Client _serving(List<int> imageBytes) {
  return MockClient.streaming((request, body) async {
    return http.StreamedResponse(Stream.value(imageBytes), HttpStatus.ok);
  });
}

Future<(LibreOfficeInstaller, FakeImageTools, LibreOfficeLayout)> _installer({
  required List<int> imageBytes,
  required ReleaseImage release,
  ImageStep? failingStep,
}) async {
  final directory = await Directory.systemTemp.createTemp('libreoffice');
  final tools = FakeImageTools(failingStep: failingStep);
  final installer = LibreOfficeInstaller(
    client: _serving(imageBytes),
    runCommand: tools.run,
    findDataDirectory: () async => directory,
    release: release,
  );

  return (installer, tools, LibreOfficeLayout(directory.path));
}

void main() {
  test(
    'LibreOfficeInstaller property installs from the verified image',
    () async {
      for (final imageBytes in examplesOf(_imageBytesOf, runs: 10)) {
        final (installer, tools, layout) = await _installer(
          imageBytes: imageBytes,
          release: _releaseOf(imageBytes),
        );

        await installer.downloadVerifiedImage(onReceived: (receivedBytes) {});

        expect(await File(layout.image).readAsBytes(), imageBytes);

        await installer.installDownloadedImage();

        final mountPoint = tools.attachedMountPoint;

        expect(await installer.isInstalled(), isTrue);
        expect(await File(layout.binary).exists(), isTrue);
        expect(await File(layout.image).exists(), isFalse);
        expect(await Directory(layout.stagedApplication).exists(), isFalse);
        expect(tools.commands, [
          [
            '/usr/bin/hdiutil',
            'attach',
            '-nobrowse',
            '-readonly',
            '-mountpoint',
            mountPoint,
            layout.image,
          ],
          [
            '/usr/bin/ditto',
            '$mountPoint/LibreOffice.app',
            layout.stagedApplication,
          ],
          ['/usr/bin/hdiutil', 'detach', mountPoint],
        ]);
      }
    },
  );

  test('downloadVerifiedImage property deletes an image that fails', () async {
    for (final imageBytes in examplesOf(_imageBytesOf, runs: 10)) {
      final (installer, tools, layout) = await _installer(
        imageBytes: imageBytes,
        release: _releaseOf([...imageBytes, 0]),
      );

      await expectLater(
        installer.downloadVerifiedImage(onReceived: (receivedBytes) {}),
        throwsA(isA<LibreOfficeSetupError>()),
      );
      expect(await File(layout.image).exists(), isFalse);
      expect(await installer.isInstalled(), isFalse);
      expect(tools.commands, isEmpty);
    }
  });

  test('installDownloadedImage property always cleans up a failure', () async {
    for (final (imageBytes, failingStep) in examplesOf(
      (random) => (_imageBytesOf(random), oneOf(random, ImageStep.values)),
      runs: 12,
    )) {
      final (installer, tools, layout) = await _installer(
        imageBytes: imageBytes,
        release: _releaseOf(imageBytes),
        failingStep: failingStep,
      );

      await installer.downloadVerifiedImage(onReceived: (receivedBytes) {});
      await expectLater(
        installer.installDownloadedImage(),
        throwsA(isA<LibreOfficeSetupError>()),
      );

      final steps = [for (final command in tools.commands) stepOf(command)];

      expect(await File(layout.image).exists(), isFalse);
      expect(await installer.isInstalled(), isFalse);
      expect(
        steps.last,
        failingStep == ImageStep.attach ? ImageStep.attach : ImageStep.detach,
      );
    }
  });

  test('remove property leaves no LibreOffice behind', () async {
    for (final imageBytes in examplesOf(_imageBytesOf, runs: 5)) {
      final (installer, tools, layout) = await _installer(
        imageBytes: imageBytes,
        release: _releaseOf(imageBytes),
      );

      await installer.downloadVerifiedImage(onReceived: (receivedBytes) {});
      await installer.installDownloadedImage();
      await installer.remove();

      expect(await installer.isInstalled(), isFalse);
      expect(await Directory(layout.application).exists(), isFalse);
      expect(tools.commands, hasLength(3));
    }
  });
}
