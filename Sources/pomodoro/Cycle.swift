import Foundation

/// Object describing a cycle.
struct Cycle: Codable, Equatable {
    /// Focusing duration of a cycle.
    var focus: Duration
    
    /// Resting duration of a cycle.
    var rest: Duration?
    
    static func makeDefault() -> Cycle {
        Cycle(
            focus: 25.0,
            rest: 5.0
        )
    }
}

extension [Cycle] {
    static func makeDefault() -> [Cycle] {
        [
            Cycle.makeDefault(),
            Cycle.makeDefault(),
            Cycle.makeDefault(),
            Cycle(focus: 25.0, rest: 30),
        ]
    }
}
