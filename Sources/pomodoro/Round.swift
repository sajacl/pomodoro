import Foundation

///// Object which is responsible for Phase management/transition in a pomorodo lifecycle.
struct Round: Codable, Equatable {
    /// A cycle in the phase.
    let cycle: Cycle

    /// Current state of a phase which will be either `focusing` or `resting`.
    private(set) var phase: Phase?

    /// State of a phase.
    enum Phase: Codable, Equatable {
        /// Focusing cycle in a phase.
        case focusing

        /// Resting cycle in a phase.
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
