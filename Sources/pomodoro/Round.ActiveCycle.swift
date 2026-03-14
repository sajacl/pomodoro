import Foundation

extension Round {
    struct ActiveCycle: Equatable, Codable {
        let index: UInt

        let cycle: pomodoro.Cycle

        var phase: Phase = .focused

        /// The duration (in minutes) of the current phase.
        var duration: Duration {
            switch phase {
                case .focused:
                    return cycle.focus

                case .resting:
                    return cycle.rest ?? 0
            }
        }
    }
}
