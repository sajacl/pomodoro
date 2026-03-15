import Foundation

/// Represents a single phase (either focusing or resting) in the Pomodoro.
///
/// Each phase holds a duration (in minutes), defining how long the focus or rest period lasts.
/// Used to track the user's current activity for productivity timing.
enum Phase: Equatable, Codable {
    /// The focus (work) phase.
    case focused

    /// The rest (break) phase
    case resting
}
