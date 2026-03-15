import Foundation

extension Round.ActiveCycle {
    /// Tracks and increments elapsed time within a single Pomodoro phase,
    /// determining whether the phase is still in progress or has ended.
    ///
    /// `Iterator` is initialized with a `horizon` (the total duration of the phase, in minutes),
    /// and uses an internal counter (`elapsedDuration`) to track minutes elapsed in the current phase.
    /// Calling `next()` increments the elapsed time and returns whether the phase is still in progress
    /// (`.inProgress`) or has ended (`.endOfPhase`), allowing callers to drive phase transitions as needed.
    ///
    /// Used internally within `Round.ActiveCycle` to drive the timing logic of focus and rest phases.
    struct Iterator: Equatable, Codable {
        /// The total duration of the current Pomodoro phase, in minutes.
        let horizon: Duration

        /// Amount of time elapsed within the current phase, measured in minutes.
        ///
        /// This is compared against the current phase's duration (`Round.cycle.duration`)
        /// to determine when to trigger a phase transition.
        private var elapsedDuration: Duration = 0.0

        init(horizon: Duration) {
            self.horizon = horizon
        }

        /// Advances the iterator by one minute, returning whether the phase is still in progress or has ended.
        ///
        /// - Returns: A `Result` value indicating progress and current elapsed time, or that the phase has ended.
        @MainActor
        mutating func next() -> Result {
            defer {
                elapsedDuration += 1.0
            }

            let isCounterPassedHorizon: Bool = {
                let horizonDuration = horizon * 60.0

                return elapsedDuration > horizonDuration
            }()

            if isCounterPassedHorizon {
                return .endOfPhase
            }

            return .inProgress(elapsedDuration, horizon)
        }

        /// The result of advancing the iterator.
        enum Result {
            /// The phase is still in progress.
            /// Carries the current elapsed duration and horizon.
            case inProgress(Duration, Duration)

            /// The phase has ended.
            case endOfPhase
        }
    }
}
