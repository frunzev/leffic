import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_field.dart';
import '../../shared/design/meter.dart';
import '../../shared/design/toast_host.dart';
import 'component_row.dart';
import 'libreoffice_messages.dart';
import 'libreoffice_release.dart';
import 'libreoffice_setup.dart';

const String _title = 'LibreOffice';
const String _purpose = 'Opens and reads Word, Excel and PowerPoint files';
const int _wholePercent = 100;

class LibreOfficeRow extends StatefulWidget {
  const LibreOfficeRow({required this.setup, super.key});

  final LibreOfficeSetup setup;

  @override
  State<LibreOfficeRow> createState() => _LibreOfficeRowState();
}

class _LibreOfficeRowState extends State<LibreOfficeRow> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.setup.refresh());
  }

  Future<void> _download() async {
    final toasts = ToastHost.of(context);
    final progressToast = toasts.show(libreOfficeDownloadingMessage);

    await widget.setup.download();
    toasts.dismiss(progressToast);

    final outcome = widget.setup.value;

    if (outcome is LibreOfficeFailed) {
      toasts.show(libreOfficeFailureMessage(outcome.reason));
      return;
    }

    toasts.show(libreOfficeInstalledMessage);
  }

  Widget _rowFor(LibreOfficeState state) {
    final downloadSize = downloadSizeLabel(widget.setup.downloadBytes);
    final offeredDescription = '$_purpose. $downloadSize download.';

    return switch (state) {
      LibreOfficeChecking() => ComponentRow(
        title: _title,
        description: offeredDescription,
      ),
      LibreOfficeMissing() => ComponentRow(
        title: _title,
        description: offeredDescription,
        actions: [DesignButton(label: 'Download', onPressed: _download)],
      ),
      LibreOfficeDownloading(:final percent) => ComponentRow(
        title: _title,
        description: offeredDescription,
        details: [
          MeterBlock(
            startLabel: 'Downloading',
            endLabel: '$percent%',
            fraction: percent / _wholePercent,
          ),
        ],
      ),
      LibreOfficeInstalling() => ComponentRow(
        title: _title,
        description: offeredDescription,
        details: const [
          MeterBlock(startLabel: 'Installing', endLabel: '100%', fraction: 1),
        ],
      ),
      LibreOfficeInstalled() => ComponentRow(
        title: _title,
        description: '$_purpose. Installed on this Mac.',
        actions: [
          DesignButton(
            label: 'Remove',
            variant: ButtonVariant.dangerOutline,
            onPressed: widget.setup.remove,
          ),
        ],
      ),
      LibreOfficeFailed(:final reason) => ComponentRow(
        title: _title,
        description: offeredDescription,
        actions: [DesignButton(label: 'Try again', onPressed: _download)],
        details: [FieldError(message: reason)],
      ),
    };
  }

  Widget _buildState(
    BuildContext context,
    LibreOfficeState state,
    Widget? child,
  ) {
    return _rowFor(state);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LibreOfficeState>(
      valueListenable: widget.setup,
      builder: _buildState,
    );
  }
}
