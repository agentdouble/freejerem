import Foundation
import FreeJeremCore

struct DailyActivitySnapshot {
    let dayStart: Double
    let textTarget: Int
    let textCount: Int
    let mouseTarget: Int
    let mouseCount: Int
}

@MainActor
final class DailyActivityLedger {
    private enum Key {
        static let dayStart = "activityDayStart"
        static let textTarget = "dailyTextTarget"
        static let textCount = "dailyTextCount"
        static let mouseTarget = "dailyMouseTarget"
        static let mouseCount = "dailyMouseCount"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func textTarget(using profile: DailyActivityProfile, on date: Date = Date()) -> Int {
        resetIfNeeded(on: date)
        let storedTarget = defaults.integer(forKey: Key.textTarget)
        if storedTarget > 0 { return storedTarget }

        let target = profile.randomCharacterBudget()
        defaults.set(target, forKey: Key.textTarget)
        return target
    }

    func textCount(on date: Date = Date()) -> Int {
        resetIfNeeded(on: date)
        return defaults.integer(forKey: Key.textCount)
    }

    func recordTextCharacters(_ count: Int, on date: Date = Date()) {
        resetIfNeeded(on: date)
        defaults.set(textCount(on: date) + max(0, count), forKey: Key.textCount)
    }

    func mouseTarget(
        using profile: DailyActivityProfile,
        baseInterval: TimeInterval,
        on date: Date = Date()
    ) -> Int {
        resetIfNeeded(on: date)
        let storedTarget = defaults.integer(forKey: Key.mouseTarget)
        if storedTarget > 0 { return storedTarget }

        let target = max(1, Int(profile.workdayDuration / max(1, baseInterval)))
        defaults.set(target, forKey: Key.mouseTarget)
        return target
    }

    func mouseCount(on date: Date = Date()) -> Int {
        resetIfNeeded(on: date)
        return defaults.integer(forKey: Key.mouseCount)
    }

    func recordMouseMovement(on date: Date = Date()) {
        resetIfNeeded(on: date)
        defaults.set(mouseCount(on: date) + 1, forKey: Key.mouseCount)
    }

    func snapshot() -> DailyActivitySnapshot {
        DailyActivitySnapshot(
            dayStart: defaults.double(forKey: Key.dayStart),
            textTarget: defaults.integer(forKey: Key.textTarget),
            textCount: defaults.integer(forKey: Key.textCount),
            mouseTarget: defaults.integer(forKey: Key.mouseTarget),
            mouseCount: defaults.integer(forKey: Key.mouseCount)
        )
    }

    func restore(_ snapshot: DailyActivitySnapshot) {
        defaults.set(snapshot.dayStart, forKey: Key.dayStart)
        defaults.set(snapshot.textTarget, forKey: Key.textTarget)
        defaults.set(snapshot.textCount, forKey: Key.textCount)
        defaults.set(snapshot.mouseTarget, forKey: Key.mouseTarget)
        defaults.set(snapshot.mouseCount, forKey: Key.mouseCount)
    }

    private func resetIfNeeded(on date: Date) {
        let start = calendar.startOfDay(for: date).timeIntervalSince1970
        guard defaults.double(forKey: Key.dayStart) != start else { return }

        defaults.set(start, forKey: Key.dayStart)
        defaults.set(0, forKey: Key.textTarget)
        defaults.set(0, forKey: Key.textCount)
        defaults.set(0, forKey: Key.mouseTarget)
        defaults.set(0, forKey: Key.mouseCount)
    }
}
