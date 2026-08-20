import AppKit

@MainActor
final class AutomationCoordinator {
    let mouseAutomation: MouseAutomation
    let textAutomation: TextDocumentAutomation
    var onStateChange: (() -> Void)?

    init(mouseAutomation: MouseAutomation, textAutomation: TextDocumentAutomation) {
        self.mouseAutomation = mouseAutomation
        self.textAutomation = textAutomation
        mouseAutomation.onFailure = { [weak self] error in self?.handle(error) }
        textAutomation.onFailure = { [weak self] error in self?.handle(error) }
        mouseAutomation.onFinished = { [weak self] in self?.onStateChange?() }
        textAutomation.onFinished = { [weak self] in self?.onStateChange?() }
    }

    func toggleMouse() { toggle(mouseAutomation) }
    func toggleText() { toggle(textAutomation) }

    var isMixedModeRunning: Bool {
        mouseAutomation.isRunning && textAutomation.isRunning
    }

    func toggleMixed() {
        if isMixedModeRunning {
            stopAll()
            return
        }

        do {
            if !mouseAutomation.isRunning { try mouseAutomation.start() }
            if !textAutomation.isRunning { try textAutomation.start() }
            onStateChange?()
        } catch {
            mouseAutomation.stop()
            textAutomation.stop()
            handle(error)
        }
    }

    func stopAll() {
        mouseAutomation.stop()
        textAutomation.stop()
        onStateChange?()
    }

    private func toggle(_ automation: AutomationService) {
        if automation.isRunning {
            automation.stop()
        } else {
            do { try automation.start() } catch { handle(error) }
        }
        onStateChange?()
    }

    private func handle(_ error: Error) {
        onStateChange?()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "FreeJerem"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
