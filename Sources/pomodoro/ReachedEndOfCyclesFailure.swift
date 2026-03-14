import Foundation

/// Error thrown when all cycles in a Pomodoro round have been completed.
struct ReachedEndOfCyclesFailure: LocalizedError {
    var errorDescription: String? {
        "Reached the end of cycles."
    }
}
