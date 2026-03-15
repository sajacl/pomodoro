import Foundation

/// Describes a single Pomodoro cycle.
struct Cycle: Codable, Equatable {
    /// Duration (in minutes) for focusing.
    var focus: Duration

    /// Optional duration (in minutes) for resting.
    var rest: Duration
}
