import Foundation

public struct DailyActivityProfile: Sendable {
    public let workdayDuration: TimeInterval
    public let characterBudget: ClosedRange<Int>
    public let burstLength: ClosedRange<Int>
    public let shortBreak: ClosedRange<TimeInterval>
    public let longBreak: ClosedRange<TimeInterval>
    public let longBreakProbability: Double
    public let mouseIntervalMultiplier: ClosedRange<Double>

    public static let computerWorkday = DailyActivityProfile(
        workdayDuration: 8 * 60 * 60,
        characterBudget: 3_500...8_000,
        burstLength: 15...65,
        shortBreak: 45...180,
        longBreak: 300...900,
        longBreakProbability: 0.07,
        mouseIntervalMultiplier: 0.6...2.4
    )

    public func randomCharacterBudget() -> Int {
        Int.random(in: characterBudget)
    }

    public func randomBurstLength() -> Int {
        Int.random(in: burstLength)
    }

    public func randomBreakDuration() -> TimeInterval {
        if Double.random(in: 0...1) < longBreakProbability {
            return Double.random(in: longBreak)
        }
        return Double.random(in: shortBreak)
    }

    public func randomTypingDelay(baseInterval: TimeInterval, after character: Character) -> TimeInterval {
        let multiplier: ClosedRange<Double>
        switch character {
        case ".", ",", "!", "?", ";", ":": multiplier = 1.8...3.2
        case " ", "\n": multiplier = 0.8...1.6
        default: multiplier = 0.55...1.45
        }
        return max(0.05, baseInterval * Double.random(in: multiplier))
    }

    public func randomMouseInterval(around baseInterval: TimeInterval) -> TimeInterval {
        min(180, max(8, baseInterval * Double.random(in: mouseIntervalMultiplier)))
    }
}
