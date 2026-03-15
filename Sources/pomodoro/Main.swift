import Foundation
import ArgumentParser

/// RunLoop interval in seconds.
private let interval: TimeInterval = 1.0

typealias ShouldContinue = Bool

@main
@available(macOS 12, iOS 15, visionOS 1, tvOS 15, watchOS 8, *)
struct Main: AsyncParsableCommand {
    /// Duration of the pomodoro timer, in minutes.
    /// Which will be recieved from standard output.
    @Argument(help: "Duration of the pomodoro counter, in minutes.")
    var focusDuration: Duration = {
        #if DEBUG
            return 0.1
        #else
            return 25.0
        #endif
    }()

    /// Duration of the rest timer, in minutes.
    /// Which will be recieved from standard output.
    @Option(
        name: [.customLong("rest"), .customShort("r")],
        help: "Duration of the resting counter, in minutes."
    )
    var restDuration: Duration = {
        #if DEBUG
            return 0.1
        #else
            return 5.0
        #endif
    }()

    /// Duration of the rest timer, in minutes.
    /// Which will be recieved from standard output.
    @Option(
        name: [.customLong("cycles"), .customShort("c")],
        help: "Cycles of the pomodoro counter."
    )
    var cycleCount: UInt8 = 4

    /// Duration of the rest timer, in minutes.
    /// Which will be recieved from standard output.
    @Option(
        name: [.customLong("auto_advance"), .customShort("a")],
        help: "Flag indicating if the counter should automatically advance to the next phase after completion."
    )
    var autoAdvance: Bool = {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }()

    private var state: State = .notStarted

    /// Application state machine.
    private enum State: Codable/*, Comparable*/ {
        /// Application has been fired but argument parser didnot hand it over.
        case notStarted

        /// Application is ready to start with given durations.
        case readyToStart

        /// Application
        case running/*(Phase)*/

        /// 
        case paused
    }

    private var iterator: Pomodoro!

    // MARK: Main
    @MainActor
    mutating func run() async throws {
        // - bootstrap

        // guard against zero cycle count.
        guard cycleCount > 0 else {
            print("Cycle count must be greater than zero.")
            return
        }

        // guard against minus durations.
        guard focusDuration > 0.0, restDuration >= 0.0 else {
            print("Cycle count must be greater than zero.")
            return
        }

        state = .readyToStart

        // - initialization
        iterator = Pomodoro.makeDefault(autoAdvance: autoAdvance)

        iterator.start(cycles: cycleCount, with: focusDuration, and: restDuration)
        state = .running

        // - run loop
        while true {
            do {
                try iterator.advance()
            } catch is Round.ReachedEndOfCyclesFailure {
                // ask user
                // iterator.start(cycles: cycleCount, with: focusDuration, and: restDuration)
                break
            } catch {
                break
            }

            try await Task.sleep(for: .seconds(interval))
        }
    }
}
