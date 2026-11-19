import 'package:flutter/services.dart';

import 'page_position.dart';

const String pdfPageViewType = 'leffic/pdf-page-view';
const String _loadDocumentMethod = 'loadDocument';
const String _goToPageMethod = 'goToPage';
const String _visiblePageChangedMethod = 'visiblePageChanged';

String pdfPageChannelName(int viewId) => '$pdfPageViewType/$viewId';

int _pageNumberFrom(Object? reported) {
  if (reported is! int || reported < firstPage) {
    throw FormatException('The PDF viewer reported no page number', reported);
  }

  return reported;
}

class PdfPageChannel {
  PdfPageChannel({required int viewId, required this.onVisiblePageChanged})
    : _channel = MethodChannel(pdfPageChannelName(viewId));

  final MethodChannel _channel;
  final ValueChanged<int> onVisiblePageChanged;

  void startReporting() {
    _channel.setMethodCallHandler(_receive);
  }

  void stopReporting() {
    _channel.setMethodCallHandler(null);
  }

  Future<int> loadDocument(String path) async {
    final pageCount = await _channel.invokeMethod<int>(
      _loadDocumentMethod,
      path,
    );

    return _pageNumberFrom(pageCount);
  }

  Future<void> goToPage(int page) async {
    await _channel.invokeMethod<void>(_goToPageMethod, page);
  }

  Future<void> _receive(MethodCall call) async {
    if (call.method != _visiblePageChangedMethod) {
      throw MissingPluginException('The PDF viewer has no ${call.method}');
    }

    onVisiblePageChanged(_pageNumberFrom(call.arguments));
  }
}
