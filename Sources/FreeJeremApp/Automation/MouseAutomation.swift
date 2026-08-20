import CoreGraphics
import Foundation
import FreeJeremCore

@MainActor
final class MouseAutomation: AutomationService {
    private let preferences: PreferencesStore
    private let activityLedger: DailyActivityLedger
    private let profile: DailyActivityProfile
    private var timer: Timer?
    private var startedAt: Date?
    private var dailyTarget = 0

    private(set) var isRunning = false
    var onFailure: ((Error) -> Void)?
    var onFinished: (() -> Void)?

    var dailyProgress: (count: Int, target: Int) {
        (
            activityLedger.mouseCount(),
            activityLedger.mouseTarget(
                using: profile,
                baseInterval: preferences.mouseInterval
            )
        )
    }

    init(
        preferences: PreferencesStore,
        activityLedger: DailyActivityLedger,
        profile: DailyActivityProfile = .computerWorkday
    ) {
        self.preferences = preferences
        self.activityLedger = activityLedger
        self.profile = profile
    }

    func start() throws {
        guard !isRunning else { return }
        guard CGEvent(source: nil) != nil else {
            throw AutomationError.mouseEventUnavailable
        }
        dailyTarget = activityLedger.mouseTarget(
            using: profile,
            baseInterval: preferences.mouseInterval
        )
        guard activityLedger.mouseCount() < dailyTarget else {
            onFinished?()
            return
        }

        startedAt = Date()
        isRunning = true
        movePointer()
        scheduleNextMovement()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        startedAt = nil
    }

    private func scheduleNextMovement() {
        guard let startedAt,
              Date().timeIntervalSince(startedAt) < profile.workdayDuration,
              activityLedger.mouseCount() < dailyTarget else {
            finishDay()
            return
        }

        timer?.invalidate()
        let interval = profile.randomMouseInterval(around: preferences.mouseInterval)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isRunning else { return }
                self.movePointer()
                self.scheduleNextMovement()
            }
        }
    }

    private func movePointer() {
        guard let event = CGEvent(source: nil) else {
            fail(with: AutomationError.mouseEventUnavailable)
            return
        }

        let origin = event.location
        let distance = Int(preferences.mouseDistance.rounded())
        var deltaX = Int.random(in: -distance...distance)
        let deltaY = Int.random(in: -distance...distance)
        if deltaX == 0 && deltaY == 0 { deltaX = 1 }

        let bounds = displayBounds(containing: origin)
        let target = MouseTargetCalculator.target(
            from: origin,
            deltaX: CGFloat(deltaX),
            deltaY: CGFloat(deltaY),
            visibleBounds: bounds.insetBy(dx: 1, dy: 1)
        )
        let result = CGWarpMouseCursorPosition(target)
        if result != .success {
            fail(with: AutomationError.mouseMovementFailed(result))
        } else {
            activityLedger.recordMouseMovement()
        }
    }

    private func displayBounds(containing point: CGPoint) -> CGRect {
        var displayID = CGMainDisplayID()
        var displayCount: UInt32 = 0
        let result = CGGetDisplaysWithPoint(point, 1, &displayID, &displayCount)
        guard result == .success, displayCount > 0 else {
            return CGDisplayBounds(CGMainDisplayID())
        }
        return CGDisplayBounds(displayID)
    }

    private func fail(with error: Error) {
        stop()
        onFailure?(error)
    }

    private func finishDay() {
        stop()
        onFinished?()
    }
}
