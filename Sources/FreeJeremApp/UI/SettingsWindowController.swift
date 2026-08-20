import AppKit
import UniformTypeIdentifiers

@MainActor
final class SettingsWindowController: NSWindowController {
    private let preferences: PreferencesStore
    private let mouseIntervalField = NSTextField()
    private let mouseDistanceField = NSTextField()
    private let textIntervalField = NSTextField()
    private let filePathField = NSTextField()

    init(preferences: PreferencesStore) {
        self.preferences = preferences
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 290),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        configureWindow()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func present() {
        loadValues()
        NSApplication.shared.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func configureWindow() {
        window?.title = "Réglages FreeJerem"
        window?.center()
        window?.isReleasedWhenClosed = false

        mouseIntervalField.placeholderString = "20"
        mouseDistanceField.placeholderString = "12"
        textIntervalField.placeholderString = "0,4"
        filePathField.isEditable = false
        filePathField.lineBreakMode = .byTruncatingMiddle

        let form = NSGridView(views: [
            [label("Souris — intervalle moyen (s) :"), mouseIntervalField],
            [label("Souris — distance (px) :"), mouseDistanceField],
            [label("Texte — rythme de base (s) :"), textIntervalField],
            [label("Fichier texte :"), filePathField]
        ])
        form.rowSpacing = 10
        form.columnSpacing = 12
        form.column(at: 0).xPlacement = .trailing
        form.column(at: 1).xPlacement = .fill

        let chooseButton = NSButton(title: "Choisir un autre fichier…", target: self, action: #selector(chooseFile))
        let spacer = NSView()
        let saveButton = NSButton(title: "Enregistrer", target: self, action: #selector(saveSettings))
        saveButton.keyEquivalent = "\r"
        let buttons = NSStackView(views: [chooseButton, spacer, saveButton])
        buttons.orientation = .horizontal

        let stack = NSStackView(views: [form, buttons])
        stack.orientation = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        window?.contentView?.addSubview(stack)

        if let contentView = window?.contentView {
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
                stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
                stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
                spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
            ])
        }
    }

    private func loadValues() {
        mouseIntervalField.doubleValue = preferences.mouseInterval
        mouseDistanceField.doubleValue = Double(preferences.mouseDistance)
        textIntervalField.doubleValue = preferences.textInterval
        filePathField.stringValue = preferences.textFileURL.path
    }

    private func label(_ title: String) -> NSTextField {
        let field = NSTextField(labelWithString: title)
        field.alignment = .right
        return field
    }

    @objc private func chooseFile() {
        let panel = NSSavePanel()
        panel.title = "Choisir ou créer le fichier texte"
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = preferences.textFileURL.lastPathComponent
        panel.directoryURL = preferences.textFileURL.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        preferences.textFileURL = url
        filePathField.stringValue = url.path
    }

    @objc private func saveSettings() {
        preferences.mouseInterval = mouseIntervalField.doubleValue
        preferences.mouseDistance = CGFloat(mouseDistanceField.doubleValue)
        preferences.textInterval = textIntervalField.doubleValue
        window?.close()
    }
}
