import Foundation

/// <#Description#>
struct Iterator: Equatable, Codable {
    /// The current round of Pomodoro cycles being run.
    let horizon: Duration
    
    /// Amount of time elapsed within the current phase, measured in minutes.
    ///
    /// This is compared against the current phase's duration (`Round.cycle.duration`)
    /// to determine when to trigger a phase transition.
    private var elapsedDuration: Duration = 0.0
    
    init(horizon: Duration) {
        self.horizon = horizon
    }
    
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

    enum Result {
        case inProgress(Duration, Duration)

        case endOfPhase
    }
}
