import Foundation

/// Describes a single Pomodoro cycle.
struct Cycle: Codable, Equatable {
    /// Duration (in minutes) for focusing.
    var focus: Duration

    /// Optional duration (in minutes) for resting.
    var rest: Duration?
}

extension [Cycle] {
    /// Creates a list of cycles with a specified focus, rest duration, and count.
    /// The last cycle has a longer rest period.
    static func create(
        focusDuration: Duration,
        restDuration: Duration,
        cycleCount: UInt8
    ) -> [Cycle] {
        var cycles: [Cycle] = []
        cycles.reserveCapacity(Int(cycleCount))

        for _ in 0..<(cycleCount - 1) {
            cycles.append(
                Cycle(focus: focusDuration, rest: restDuration)
            )
        }

        // contains longer resting cycle
        cycles.append(Cycle(focus: focusDuration, rest: 7.5 * Double(cycleCount)))

        return cycles
    }
}
