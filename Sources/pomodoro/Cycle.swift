import Foundation

/// Object describing a cycle.
struct Cycle: Codable, Equatable {
    /// Focusing duration of a cycle.
    var focus: Duration

    /// Resting duration of a cycle.
    var rest: Duration?
}

extension [Cycle] {
    static func makeDefault(
        focusDuration: Duration,
        restDuration: Duration,
        cycleCount: UInt8
    ) -> [Cycle] {
        var cycles: [Cycle] = []
        cycles.reserveCapacity(Int(cycleCount))

        for _ in 0..<cycleCount - 1 {
            cycles.append(
                Cycle(focus: focusDuration, rest: restDuration)
            )
        }

        // contains longer resting cycle
        cycles.append(Cycle(focus: focusDuration, rest: 30.0))

        return cycles
    }
}
