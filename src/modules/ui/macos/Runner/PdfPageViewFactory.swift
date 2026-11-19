import FlutterMacOS

class PdfPageViewFactory: NSObject, FlutterPlatformViewFactory {
  static let viewType = "leffic/pdf-page-view"

  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func create(
    withViewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> NSView {
    let channel = FlutterMethodChannel(
      name: "\(PdfPageViewFactory.viewType)/\(viewId)",
      binaryMessenger: messenger
    )

    return PdfPageView(channel: channel)
  }
}
