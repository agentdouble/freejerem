import Foundation
import FreeJeremCore

@MainActor
final class TextDocumentAutomation: AutomationService {
    private let preferences: PreferencesStore
    private let activityLedger: DailyActivityLedger
    private let windowController: TextDocumentWindowController
    private let profile: DailyActivityProfile
    private var generator = RandomTextGenerator()
    private var timer: Timer?
    private var pendingCharacters: [Character] = []
    private var startedAt: Date?
    private var dailyTarget = 0

    private(set) var isRunning = false
    var onFailure: ((Error) -> Void)?
    var onFinished: (() -> Void)?

    var dailyProgress: (count: Int, target: Int) {
        (
            activityLedger.textCount(),
            activityLedger.textTarget(using: profile)
        )
    }

    init(
        preferences: PreferencesStore,
        activityLedger: DailyActivityLedger,
        windowController: TextDocumentWindowController,
        profile: DailyActivityProfile = .computerWorkday
    ) {
        self.preferences = preferences
        self.activityLedger = activityLedger
        self.windowController = windowController
        self.profile = profile
    }

    func start() throws {
        guard !isRunning else { return }
        let fileURL = preferences.textFileURL
        do {
            try ensureFileExists(at: fileURL)
            try windowController.open(fileURL: fileURL)
        } catch {
            throw AutomationError.cannotCreateTextFile(fileURL, error)
        }

        dailyTarget = activityLedger.textTarget(using: profile)
        guard activityLedger.textCount() < dailyTarget else {
            onFinished?()
            return
        }

        generator = RandomTextGenerator()
        pendingCharacters.removeAll()
        startedAt = Date()
        isRunning = true
        scheduleNextStep(after: 0.05)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        startedAt = nil
        pendingCharacters.removeAll()
        do {
            try windowController.save()
        } catch {
            onFailure?(AutomationError.cannotWriteTextFile(preferences.textFileURL, error))
        }
    }

    private func scheduleNextStep(after delay: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.typeNextCharacter() }
        }
    }

    private func typeNextCharacter() {
        guard isRunning else { return }
        guard let startedAt,
              Date().timeIntervalSince(startedAt) < profile.workdayDuration,
              activityLedger.textCount() < dailyTarget else {
            finishDay()
            return
        }

        if pendingCharacters.isEmpty {
            let remaining = dailyTarget - activityLedger.textCount()
            let length = min(profile.randomBurstLength(), remaining)
            pendingCharacters = Array(generator.nextBurst(maxCharacters: length))
        }

        guard !pendingCharacters.isEmpty else {
            finishDay()
            return
        }

        let character = pendingCharacters.removeFirst()
        do {
            try windowController.append(String(character))
            activityLedger.recordTextCharacters(1)
        } catch {
            timer?.invalidate()
            timer = nil
            isRunning = false
            onFailure?(AutomationError.cannotWriteTextFile(preferences.textFileURL, error))
            return
        }

        guard activityLedger.textCount() < dailyTarget else {
            finishDay()
            return
        }

        let delay = pendingCharacters.isEmpty
            ? profile.randomBreakDuration()
            : profile.randomTypingDelay(baseInterval: preferences.textInterval, after: character)
        scheduleNextStep(after: delay)
    }

    private func finishDay() {
        stop()
        onFinished?()
    }

    private func ensureFileExists(at fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}
