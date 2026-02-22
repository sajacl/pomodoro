import Foundation
import ArgumentParser

/// Gap interval in seconds.
private let interval: Duration = 1.0

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

typealias CanContinue = Bool

typealias Duration = TimeInterval
//private typealias RemainingDuration = TimeInterval

@main
@available(macOS 12, iOS 15, visionOS 1, tvOS 15, watchOS 8, *)
@MainActor
struct pomodoro: AsyncParsableCommand {
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
    var autoAdvance: Bool = false

    private var state: State = .notStarted {
        didSet {
            #if DEBUG
                print(state)
            #endif
        }
    }

    /// Application state machine.
    private enum State: Codable/*, Comparable*/ {
        /// Application has been fired but argument parser didnot hand it over.
        case notStarted

        /// Application is ready to start with given durations.
        case readyToStart(cycles: [Cycle])

        /// Application
        case running/*(Phase)*/

        /// 
        case paused
    }

    private var phaseManager: PhaseManager!

    // MARK: Main
    mutating func run() async throws {
        let cycles: [Cycle] = .create(
            focusDuration: focusDuration,
            restDuration: restDuration,
            cycleCount: cycleCount
        )

        // initial state
        state = .readyToStart(cycles: cycles)

        phaseManager = PhaseManager(autoAdvance: autoAdvance, cycles: cycles)

        phaseManager.start()
        state = .running

        // run loop
        while true {
            if !phaseManager.advance() {
                break
            }

            try await Task.sleep(for: .seconds(interval))
        }
    }
}
