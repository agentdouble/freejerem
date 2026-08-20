import AppKit
import CoreGraphics

@MainActor
final class SmokeTestRunner {
    private let coordinator: AutomationCoordinator
    private let preferences: PreferencesStore
    private let activityLedger: DailyActivityLedger
    private var timer: Timer?

    init(
        coordinator: AutomationCoordinator,
        preferences: PreferencesStore,
        activityLedger: DailyActivityLedger
    ) {
        self.coordinator = coordinator
        self.preferences = preferences
        self.activityLedger = activityLedger
    }

    func runIfRequested(environment: [String: String] = ProcessInfo.processInfo.environment) {
        guard let mode = environment["FREEJEREM_SMOKE_TEST"] else { return }

        switch mode {
        case "text":
            runTextCheck(filePath: environment["FREEJEREM_TEXT_FILE"])
        case "mouse":
            runMouseCheck()
        case "mixed":
            runMixedCheck(filePath: environment["FREEJEREM_TEXT_FILE"])
        default:
            fputs("SMOKE_ERROR unknown mode\n", stderr)
            NSApplication.shared.terminate(nil)
        }
    }

    private func runTextCheck(filePath: String?) {
        let originalFileURL = preferences.textFileURL
        let originalInterval = preferences.textInterval
        let activitySnapshot = activityLedger.snapshot()
        resetActivityForCheck()
        if let filePath, !filePath.isEmpty {
            preferences.textFileURL = URL(fileURLWithPath: filePath)
        }
        preferences.textInterval = 0.1
        coordinator.toggleText()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.coordinator.stopAll()
                let size = (try? FileManager.default.attributesOfItem(
                    atPath: self.preferences.textFileURL.path
                )[.size] as? NSNumber)?.intValue ?? 0
                self.preferences.textFileURL = originalFileURL
                self.preferences.textInterval = originalInterval
                self.activityLedger.restore(activitySnapshot)
                print(size > 0 ? "SMOKE_TEXT_OK bytes=\(size)" : "SMOKE_TEXT_ERROR empty file")
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func runMouseCheck() {
        let origin = CGEvent(source: nil)?.location
        let activitySnapshot = activityLedger.snapshot()
        resetActivityForCheck()
        coordinator.toggleMouse()

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let destination = CGEvent(source: nil)?.location
                self.coordinator.stopAll()
                self.activityLedger.restore(activitySnapshot)
                if let origin, let destination, origin != destination {
                    print("SMOKE_MOUSE_OK from=\(origin) to=\(destination)")
                } else {
                    print("SMOKE_MOUSE_ERROR cursor unchanged")
                }
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func runMixedCheck(filePath: String?) {
        let originalFileURL = preferences.textFileURL
        let originalInterval = preferences.textInterval
        let activitySnapshot = activityLedger.snapshot()
        let origin = CGEvent(source: nil)?.location
        resetActivityForCheck()

        if let filePath, !filePath.isEmpty {
            preferences.textFileURL = URL(fileURLWithPath: filePath)
        }
        preferences.textInterval = 0.1
        coordinator.toggleMixed()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let destination = CGEvent(source: nil)?.location
                self.coordinator.stopAll()
                let size = (try? FileManager.default.attributesOfItem(
                    atPath: self.preferences.textFileURL.path
                )[.size] as? NSNumber)?.intValue ?? 0
                self.preferences.textFileURL = originalFileURL
                self.preferences.textInterval = originalInterval
                self.activityLedger.restore(activitySnapshot)

                if size > 0, let origin, let destination, origin != destination {
                    print("SMOKE_MIXED_OK bytes=\(size) from=\(origin) to=\(destination)")
                } else {
                    print("SMOKE_MIXED_ERROR bytes=\(size) cursorChanged=\(origin != destination)")
                }
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func resetActivityForCheck() {
        activityLedger.restore(DailyActivitySnapshot(
            dayStart: 0,
            textTarget: 0,
            textCount: 0,
            mouseTarget: 0,
            mouseCount: 0
        ))
    }
}
