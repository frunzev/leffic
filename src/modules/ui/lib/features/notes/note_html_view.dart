import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'note_document.dart';

const double _heightBeforeMeasuring = double.infinity;

class NoteHtmlView extends StatefulWidget {
  const NoteHtmlView({required this.html, super.key});

  final String html;

  @override
  State<NoteHtmlView> createState() => _NoteHtmlViewState();
}

class _NoteHtmlViewState extends State<NoteHtmlView> {
  final WebViewController _controller = WebViewController();
  double _contentHeight = _heightBeforeMeasuring;

  @override
  void initState() {
    super.initState();
    unawaited(_listenAndLoad());
  }

  @override
  void didUpdateWidget(NoteHtmlView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.html != widget.html) {
      unawaited(_controller.loadHtmlString(widget.html));
    }
  }

  Future<void> _listenAndLoad() async {
    await _controller.addJavaScriptChannel(
      noteHeightChannel,
      onMessageReceived: _showMeasuredHeight,
    );
    await _controller.loadHtmlString(widget.html);
  }

  void _showMeasuredHeight(JavaScriptMessage message) {
    final contentHeight = readNoteHeight(message.message);

    if (!mounted) {
      return;
    }

    setState(() => _contentHeight = contentHeight);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _contentHeight,
      child: WebViewWidget(controller: _controller),
    );
  }
}
