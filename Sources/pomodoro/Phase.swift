import Foundation

/// Object which is responsible for Phase management/transition in a pomorodo lifecycle.
struct Phase: Codable, Equatable {
    /// A cycle in the phase.
    let cycle: Cycle

    /// Current state of a phase which will be either `focusing` or `resting`.
    var state: State

    /// State of a phase.
    enum State: Codable, Equatable {
        /// Focusing cycle in a phase.
        case focusing

        /// Resting cycle in a phase.
        case resting
    }

    init(cycle: Cycle, state: State) {
        self.cycle = cycle
        self.state = state
    }
}
