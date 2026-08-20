import AppKit

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let coordinator: AutomationCoordinator
    private let preferences: PreferencesStore
    private let settingsController: SettingsWindowController
    private let textWindowController: TextDocumentWindowController
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let mouseItem = NSMenuItem()
    private let textItem = NSMenuItem()
    private let mixedItem = NSMenuItem()
    private let stopItem = NSMenuItem()
    private let textProgressItem = NSMenuItem()
    private let mouseProgressItem = NSMenuItem()

    init(
        coordinator: AutomationCoordinator,
        preferences: PreferencesStore,
        settingsController: SettingsWindowController,
        textWindowController: TextDocumentWindowController
    ) {
        self.coordinator = coordinator
        self.preferences = preferences
        self.settingsController = settingsController
        self.textWindowController = textWindowController
        super.init()
    }

    func install() {
        statusItem.button?.toolTip = "FreeJerem"
        let menu = NSMenu()
        menu.delegate = self

        mouseItem.target = self
        mouseItem.action = #selector(toggleMouse)
        mouseItem.keyEquivalent = "m"
        mouseItem.keyEquivalentModifierMask = [.command, .option]

        textItem.target = self
        textItem.action = #selector(toggleText)
        textItem.keyEquivalent = "t"
        textItem.keyEquivalentModifierMask = [.command, .option]

        mixedItem.target = self
        mixedItem.action = #selector(toggleMixed)
        mixedItem.keyEquivalent = "a"
        mixedItem.keyEquivalentModifierMask = [.command, .option]

        stopItem.title = "Tout arrêter"
        stopItem.target = self
        stopItem.action = #selector(stopAll)
        stopItem.keyEquivalent = "s"
        stopItem.keyEquivalentModifierMask = [.command, .option]

        menu.addItem(mouseItem)
        menu.addItem(textItem)
        menu.addItem(mixedItem)
        menu.addItem(stopItem)
        menu.addItem(.separator())
        textProgressItem.isEnabled = false
        mouseProgressItem.isEnabled = false
        menu.addItem(textProgressItem)
        menu.addItem(mouseProgressItem)
        menu.addItem(.separator())
        menu.addItem(item(title: "Ouvrir le fichier texte", action: #selector(openTextFile)))
        menu.addItem(item(title: "Afficher le fichier dans le Finder", action: #selector(revealTextFile)))
        menu.addItem(.separator())
        let settingsItem = item(title: "Réglages…", action: #selector(openSettings))
        settingsItem.keyEquivalent = ","
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = item(title: "Quitter FreeJerem", action: #selector(quit))
        quitItem.keyEquivalent = "q"
        menu.addItem(quitItem)

        statusItem.menu = menu
        refresh()
    }

    func refresh() {
        let mouseRunning = coordinator.mouseAutomation.isRunning
        let textRunning = coordinator.textAutomation.isRunning
        mouseItem.title = mouseRunning ? "Arrêter la souris automatique" : "Lancer la souris automatique"
        textItem.title = textRunning ? "Arrêter l’écriture automatique" : "Lancer l’écriture automatique"
        mixedItem.title = coordinator.isMixedModeRunning
            ? "Arrêter le mode mélange"
            : "Lancer le mode mélange clavier + souris"
        mouseItem.state = mouseRunning ? .on : .off
        textItem.state = textRunning ? .on : .off
        mixedItem.state = coordinator.isMixedModeRunning ? .on : .off
        stopItem.isEnabled = mouseRunning || textRunning

        let textProgress = coordinator.textAutomation.dailyProgress
        let mouseProgress = coordinator.mouseAutomation.dailyProgress
        textProgressItem.title = "Aujourd’hui : \(textProgress.count) / \(textProgress.target) caractères"
        mouseProgressItem.title = "Souris : \(mouseProgress.count) / \(mouseProgress.target) mouvements"

        let isActive = mouseRunning || textRunning
        let image = NSImage(
            systemSymbolName: isActive ? "cursorarrow.rays" : "cursorarrow.motionlines",
            accessibilityDescription: isActive ? "FreeJerem actif" : "FreeJerem inactif"
        )
        statusItem.button?.image = image
        statusItem.button?.title = image == nil ? "FJ" : ""
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    private func item(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func toggleMouse() { coordinator.toggleMouse() }
    @objc private func toggleText() { coordinator.toggleText() }
    @objc private func toggleMixed() { coordinator.toggleMixed() }
    @objc private func stopAll() { coordinator.stopAll() }
    @objc private func openSettings() { settingsController.present() }

    @objc private func openTextFile() {
        do {
            let url = preferences.textFileURL
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: url.path) {
                try "".write(to: url, atomically: true, encoding: .utf8)
            }
            try textWindowController.open(fileURL: url)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @objc private func revealTextFile() {
        openTextFile()
        textWindowController.revealFile()
    }

    @objc private func quit() {
        coordinator.stopAll()
        NSApplication.shared.terminate(nil)
    }
}
