import Foundation
import ArgumentParser

/// Represents a non-negative duration, measured in **minutes**, for any phase (focus, rest) in a Pomodoro ``Cycle``.
///
/// `Duration` is used throughout the Pomodoro timer logic to convey the length of each phase, elapsed time, and argument parsing from the command line.
/// It is always non-negative, and supports arithmetic, comparison, and conversion from numeric literals or string command line arguments.
struct Duration: Equatable, Codable,
                 ExpressibleByFloatLiteral,
                 ExpressibleByArgument,
                 Comparable,
                 CustomStringConvertible {
    /// Underlying value of the duration, in minutes.
    fileprivate var underlyingCounter: Double

    /// Creates a new `Duration` from a `Double` value (in minutes).
    /// Negative values are clamped to zero.
    init(_ duration: Double) {
        if duration < 0 {
            underlyingCounter = 0
        } else {
            underlyingCounter = duration
        }
    }

    /// Creates a new `Duration` from an `Int` value (in minutes).
    /// Negative values are clamped to zero.
    init(_ duration: Int) {
        if duration < 0 {
            underlyingCounter = 0
        } else {
            underlyingCounter = Double(duration)
        }
    }

    /// Creates a new `Duration` from a float literal (in minutes).
    ///
    /// Example:
    /// ```
    /// let d: Duration = 25.0
    /// ```
    init(floatLiteral value: FloatLiteralType) {
        underlyingCounter = value
    }

    /// Tries to create a `Duration` from a string argument (parsed as a Double, in minutes).
    ///
    /// Returns `nil` if parsing fails.
    ///
    /// - Parameter argument: String to parse as a Double (minutes).
    init?(argument: String) {
        guard let duration = Double(argument) else {
            return nil
        }

        if duration < 0 {
            underlyingCounter = 0
        } else {
            underlyingCounter = duration
        }
    }

    /// Adds two `Duration` values (in minutes), updating the left-hand value.
    static func += (lhs: inout Duration, rhs: Duration) {
        lhs.underlyingCounter += rhs.underlyingCounter
    }

    /// Multiplies two `Duration` values (in minutes) and returns a new `Duration`.
    static func * (lhs: Duration, rhs: Duration) -> Duration {
        Duration(lhs.underlyingCounter * rhs.underlyingCounter)
    }

    /// Divides the left `Duration` (in minutes) by the right `Duration`, returning a new `Duration`.
    static func / (lhs: Duration, rhs: Duration) -> Duration {
        Duration(lhs.underlyingCounter / rhs.underlyingCounter)
    }

    /// Returns `true` if the left `Duration` (in minutes) is less than the right.
    static func < (lhs: Duration, rhs: Duration) -> Bool {
        lhs.underlyingCounter < rhs.underlyingCounter
    }

    var description: String {
        // relative to minute
        let durationInSeconds = underlyingCounter * 60
        let hours = durationInSeconds / 3600
        let minutes = (durationInSeconds.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = durationInSeconds.truncatingRemainder(dividingBy: 60)

        if hours >= 1 {
            return "\(hours) hours, \(minutes) minutes, \(seconds) seconds"
        } else if minutes >= 1 {
            return "\(minutes) minutes, \(seconds) seconds"
        }

        return "\(seconds) seconds"
    }
}

extension Int {
    /// Converts a `Duration` (in minutes) to an `Int` by truncating the fractional part.
    ///
    /// Example:
    /// ```
    /// let d = Duration(25.7)
    /// let i: Int = Int(d) // = 25
    /// ```
    init(_ duration: Duration) {
        self.init(duration.underlyingCounter)
    }
}
