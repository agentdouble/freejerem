import AppKit

@MainActor
final class TextDocumentWindowController: NSWindowController, NSWindowDelegate {
    private let textView = NSTextView()
    private var fileURL: URL?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 440),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        self.init(window: window)
        configureWindow()
    }

    func open(fileURL: URL) throws {
        self.fileURL = fileURL
        textView.string = try String(contentsOf: fileURL, encoding: .utf8)
        window?.title = "FreeJerem — \(fileURL.lastPathComponent)"
        textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
        NSApplication.shared.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(textView)
    }

    func append(_ text: String) throws {
        textView.textStorage?.append(NSAttributedString(string: text))
        textView.scrollToEndOfDocument(nil)
        try save()
    }

    func save() throws {
        guard let fileURL else { return }
        try textView.string.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func revealFile() {
        guard let fileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    private func configureWindow() {
        guard let window else { return }
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        textView.isEditable = true
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.autoresizingMask = [.width]

        let scrollView = NSScrollView(frame: window.contentView?.bounds ?? .zero)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        window.contentView = scrollView
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        try? save()
        return true
    }
}
