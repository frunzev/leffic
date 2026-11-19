import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/design/toast_host.dart';
import '../../shared/office/missing_libreoffice.dart';
import '../../shared/widgets/captioned_spinner.dart';
import 'file_bar.dart';
import 'file_failure.dart';
import 'file_models.dart';
import 'file_stage.dart';

typedef OpenedFileBuilder = Widget Function(
  BuildContext context,
  OpenedFile opened,
);

class FileOpener extends StatefulWidget {
  const FileOpener({
    required this.fileName,
    required this.open,
    required this.builder,
    super.key,
  });

  final String fileName;
  final Future<OpenedFile> Function() open;
  final OpenedFileBuilder builder;

  @override
  State<FileOpener> createState() => _FileOpenerState();
}

class _FileOpenerState extends State<FileOpener> {
  OpenedFile? _opened;
  String? _failureReason;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  void _retry() {
    setState(() => _failureReason = null);
    unawaited(_open());
  }

  Future<void> _open() async {
    final OpenedFile opened;

    try {
      opened = await widget.open();
    } on Exception catch (failure) {
      _showFailure('$failure');
      return;
    }

    _showOpened(opened);
  }

  void _showFailure(String reason) {
    if (!mounted) {
      return;
    }

    if (isMissingLibreOffice(reason)) {
      ToastHost.of(context).show(missingLibreOfficeMessage);
    }

    setState(() => _failureReason = reason);
  }

  void _showOpened(OpenedFile opened) {
    if (!mounted) {
      return;
    }

    setState(() => _opened = opened);
  }

  Widget _waitingContent() {
    final failureReason = _failureReason;

    if (failureReason != null) {
      return FileFailure(
        fileName: widget.fileName,
        reason: failureReason,
        onRetry: _retry,
      );
    }

    return CaptionedSpinner(label: 'Opening ${widget.fileName}…');
  }

  @override
  Widget build(BuildContext context) {
    final opened = _opened;

    if (opened != null) {
      return widget.builder(context, opened);
    }

    return FileStage(
      bar: FileBar(fileName: widget.fileName),
      content: _waitingContent(),
    );
  }
}
