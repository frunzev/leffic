import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'document_page_reports.dart';
import 'pdf_page_channel.dart';

class PdfView extends StatefulWidget {
  const PdfView({required this.pdf, required this.pageReports, super.key});

  final File pdf;
  final DocumentPageReports pageReports;

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  PdfPageChannel? _channel;

  @override
  void dispose() {
    _channel?.stopReporting();
    super.dispose();
  }

  void _openOnceCreated(int viewId) {
    unawaited(_open(viewId));
  }

  Future<void> _open(int viewId) async {
    final channel = PdfPageChannel(
      viewId: viewId,
      onVisiblePageChanged: widget.pageReports.onVisiblePageChanged,
    );

    _channel = channel;
    channel.startReporting();

    final pageCount = await channel.loadDocument(widget.pdf.path);

    if (!mounted) {
      return;
    }

    widget.pageReports.onPageCountChanged(pageCount);
    await channel.goToPage(widget.pageReports.openingPage);
  }

  @override
  Widget build(BuildContext context) {
    return AppKitView(
      viewType: pdfPageViewType,
      onPlatformViewCreated: _openOnceCreated,
    );
  }
}
