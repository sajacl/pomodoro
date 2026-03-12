import Foundation

/// Object describing a round in pomodoro.
struct Round: Codable, Equatable {
    /// A cycle in the round.
    let cycle: Cycle

    /// Current phase of a round.
    private(set) var phase: Phase?

    enum Phase: Codable, Equatable {
        /// Focusing cycle in a round.
        case focusing

        /// Resting cycle in a round.
        case resting
    }

    init(cycle: Cycle) {
        self.cycle = cycle
    }

    mutating func start() {
        guard phase == nil else {
            fatalError()
        }

        phase = .focusing
    }

    mutating func switchToRest() {
        guard phase == .focusing else {
            fatalError()
        }

        phase = .resting
    }

    var duration: Duration? {
        guard let phase else {
            return nil
        }

        switch phase {
            case .focusing:
                return cycle.focus

            case .resting:
                return cycle.rest ?? 5.0
        }
    }
}
