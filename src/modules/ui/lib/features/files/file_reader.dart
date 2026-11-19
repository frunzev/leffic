import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/navigation/routes.dart';
import 'document_page_reports.dart';
import 'file_bar.dart';
import 'file_bookmark_button.dart';
import 'file_chip.dart';
import 'file_models.dart';
import 'file_stage.dart';
import 'file_viewer.dart';
import 'files_api.dart';
import 'page_position.dart';

typedef FileDocumentBuilder = Widget Function(DocumentPageReports pageReports);

class FileReader extends StatefulWidget {
  const FileReader({
    required this.api,
    required this.file,
    required this.details,
    required this.documentBuilder,
    required this.onGenerateStudyUnits,
    required this.onClose,
    super.key,
  });

  final FilesApi api;
  final FileArguments file;
  final StoredFileDetails details;
  final FileDocumentBuilder documentBuilder;
  final VoidCallback onGenerateStudyUnits;
  final VoidCallback onClose;

  @override
  State<FileReader> createState() => _FileReaderState();
}

class _FileReaderState extends State<FileReader> {
  late int? _bookmarkedPage = widget.details.bookmarkedPage;
  late final int _openingPage = widget.details.bookmarkedPage ?? firstPage;
  late int _pageInView = _openingPage;
  late int _pageCount = widget.details.pageCount;
  late final DocumentPageReports _pageReports = DocumentPageReports(
    openingPage: _openingPage,
    onPageCountChanged: _showPageCount,
    onVisiblePageChanged: _showPage,
  );

  void _showPageCount(int pageCount) {
    setState(() => _pageCount = pageCount);
  }

  void _showPage(int page) {
    setState(() => _pageInView = page);
  }

  Future<void> _remember(int page) async {
    final bookmarkedPage = await widget.api.bookmarkPage(
      fileId: widget.file.id,
      page: page,
    );

    if (!mounted) {
      return;
    }

    setState(() => _bookmarkedPage = bookmarkedPage);
  }

  Future<void> _forget() async {
    await widget.api.removeBookmark(widget.file.id);

    if (!mounted) {
      return;
    }

    setState(() => _bookmarkedPage = null);
  }

  @override
  Widget build(BuildContext context) {
    return FileStage(
      bar: FileBar(
        fileName: widget.file.name,
        details: [
          FileChip(label: widget.file.extension.toUpperCase()),
          PagePosition(page: _pageInView, pageCount: _pageCount),
        ],
        tools: [
          FileBookmarkButton(
            pageInView: _pageInView,
            bookmarkedPage: _bookmarkedPage,
            onRemember: _remember,
            onForget: _forget,
          ),
          DesignIconButton(
            icon: DesignIcons.closePlain,
            semanticLabel: 'Close ${widget.file.name}',
            variant: ButtonVariant.quiet,
            onPressed: widget.onClose,
          ),
        ],
        actions: [
          DesignButton(
            label: 'Generate study units',
            icon: DesignIcons.aiImport,
            onPressed: widget.onGenerateStudyUnits,
          ),
        ],
      ),
      content: FileViewer(document: widget.documentBuilder(_pageReports)),
    );
  }
}
