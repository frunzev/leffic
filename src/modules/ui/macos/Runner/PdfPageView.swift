import FlutterMacOS
import PDFKit

class PdfPageView: PDFView {
  private static let loadDocumentMethod = "loadDocument"
  private static let goToPageMethod = "goToPage"
  private static let visiblePageChangedMethod = "visiblePageChanged"
  private static let unreadableDocumentCode = "unreadable_document"
  private static let missingPageCode = "missing_page"
  private static let firstPageNumber = 1

  private let channel: FlutterMethodChannel
  private var pageAwaitingSize: PDFPage?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init(frame: .zero)

    autoScales = true
    displayMode = .singlePageContinuous
    backgroundColor = .clear
    channel.setMethodCallHandler { [weak self] call, result in
      self?.answer(call, result: result)
    }
  }

  required init?(coder: NSCoder) {
    nil
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  override func setFrameSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)
    showPageAwaitingSize()
  }

  private func answer(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case Self.loadDocumentMethod:
      result(loadDocument(at: call.arguments))
    case Self.goToPageMethod:
      result(goToPage(numbered: call.arguments))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func loadDocument(at path: Any?) -> Any {
    guard let path = path as? String,
      let loadedDocument = PDFDocument(url: URL(fileURLWithPath: path))
    else {
      return FlutterError(
        code: Self.unreadableDocumentCode,
        message: "The PDF file could not be read",
        details: path
      )
    }

    document = loadedDocument
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reportVisiblePage),
      name: .PDFViewPageChanged,
      object: self
    )

    return loadedDocument.pageCount
  }

  private func goToPage(numbered pageNumber: Any?) -> Any? {
    guard let pageNumber = pageNumber as? Int,
      let document,
      pageNumber >= Self.firstPageNumber,
      pageNumber <= document.pageCount,
      let page = document.page(at: pageNumber - Self.firstPageNumber)
    else {
      return FlutterError(
        code: Self.missingPageCode,
        message: "The PDF has no such page",
        details: pageNumber
      )
    }

    pageAwaitingSize = page
    showPageAwaitingSize()

    return nil
  }

  private func showPageAwaitingSize() {
    guard let pageAwaitingSize, !bounds.isEmpty else {
      return
    }

    self.pageAwaitingSize = nil
    layoutDocumentView()
    go(to: pageAwaitingSize)
  }

  @objc private func reportVisiblePage() {
    guard let currentPage, let document else {
      return
    }

    let pageNumber = document.index(for: currentPage) + Self.firstPageNumber

    channel.invokeMethod(
      Self.visiblePageChangedMethod,
      arguments: pageNumber
    )
  }
}
