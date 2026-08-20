import AppKit

@main
enum FreeJeremApplication {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var hotKeyManager: GlobalHotKeyManager?
    private var coordinator: AutomationCoordinator?
    private var smokeTestRunner: SmokeTestRunner?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let preferences = PreferencesStore()
        let activityLedger = DailyActivityLedger()
        let textWindowController = TextDocumentWindowController()
        let mouseAutomation = MouseAutomation(
            preferences: preferences,
            activityLedger: activityLedger
        )
        let textAutomation = TextDocumentAutomation(
            preferences: preferences,
            activityLedger: activityLedger,
            windowController: textWindowController
        )
        let coordinator = AutomationCoordinator(
            mouseAutomation: mouseAutomation,
            textAutomation: textAutomation
        )
        let settingsController = SettingsWindowController(preferences: preferences)
        let menuBarController = MenuBarController(
            coordinator: coordinator,
            preferences: preferences,
            settingsController: settingsController,
            textWindowController: textWindowController
        )
        let hotKeyManager = GlobalHotKeyManager(coordinator: coordinator)

        coordinator.onStateChange = { [weak menuBarController] in
            menuBarController?.refresh()
        }
        self.coordinator = coordinator
        self.menuBarController = menuBarController
        self.hotKeyManager = hotKeyManager

        menuBarController.install()
        hotKeyManager.registerDefaultHotKeys()

        let smokeTestRunner = SmokeTestRunner(
            coordinator: coordinator,
            preferences: preferences,
            activityLedger: activityLedger
        )
        self.smokeTestRunner = smokeTestRunner
        smokeTestRunner.runIfRequested()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stopAll()
        hotKeyManager?.unregisterAll()
    }
}
