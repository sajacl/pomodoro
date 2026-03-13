import Foundation

/// Represents a single phase (either focusing or resting) in the Pomodoro.
///
/// Each phase holds a duration (in minutes), defining how long the focus or rest period lasts.
/// Used to track the user's current activity for productivity timing.
enum Phase: Codable, Equatable {
    /// The focus (work) phase, with its duration in minutes.
    case focused(duration: Duration)

    /// The rest (break) phase, with its duration in minutes.
    case resting(duration: Duration)

    /// The duration (in minutes) of the current phase.
    var duration: Duration {
        switch self {
            case let .focused(duration):
                return duration

            case let .resting(duration):
                return duration
        }
    }
}
