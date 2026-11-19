import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/pdf_page_channel.dart';

const String _createViewMethod = 'create';
const String _viewIdArgument = 'id';
const String _loadDocumentMethod = 'loadDocument';
const String _visiblePageChangedMethod = 'visiblePageChanged';
const MethodCodec _codec = StandardMethodCodec();

class FakePdfViewer {
  FakePdfViewer({required this.tester, required this.pageCount});

  final WidgetTester tester;
  final int pageCount;
  final List<MethodCall> receivedCalls = [];
  final List<int> createdViewIds = [];

  TestDefaultBinaryMessenger get _messenger {
    return tester.binding.defaultBinaryMessenger;
  }

  String get _channelName => pdfPageChannelName(createdViewIds.single);

  void install() {
    _messenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      _answerPlatformViews,
    );
    addTearDown(_uninstall);
  }

  void _uninstall() {
    _messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);

    for (final viewId in createdViewIds) {
      _messenger.setMockMethodCallHandler(
        MethodChannel(pdfPageChannelName(viewId)),
        null,
      );
    }
  }

  Future<Object?> _answerPlatformViews(MethodCall call) async {
    if (call.method != _createViewMethod) {
      return null;
    }

    final creation = call.arguments as Map<Object?, Object?>;
    final viewId = creation[_viewIdArgument]! as int;

    createdViewIds.add(viewId);
    _messenger.setMockMethodCallHandler(
      MethodChannel(pdfPageChannelName(viewId)),
      _answerViewer,
    );

    return null;
  }

  Future<Object?> _answerViewer(MethodCall call) async {
    receivedCalls.add(call);

    if (call.method == _loadDocumentMethod) {
      return pageCount;
    }

    return null;
  }

  Future<ByteData?> showVisiblePage(Object? page) async {
    ByteData? reply;
    final message = _codec.encodeMethodCall(
      MethodCall(_visiblePageChangedMethod, page),
    );

    await _messenger.handlePlatformMessage(
      _channelName,
      message,
      (data) => reply = data,
    );

    return reply;
  }
}

void decodeViewerReply(ByteData? reply) {
  if (reply == null) {
    throw MissingPluginException('Nothing answered the PDF viewer');
  }

  _codec.decodeEnvelope(reply);
}
