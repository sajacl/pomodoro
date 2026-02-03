import Foundation
import ArgumentParser

/// Gap interval in minutes.
private let interval: TimeInterval = 1.0 * 60

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

@main
@available(macOS 12, iOS 15, visionOS 1, tvOS 15, watchOS 8, *)
struct pomodoro: AsyncParsableCommand {
    /// Duration of the pomodoro timer, in minutes.
    /// Which will be recieved from standard output.
    @Argument(help: "Duration of the pomodoro timer, in minutes.")
    var focusDuration: TimeInterval = 25.0
    
    /// Duration of the rest timer, in minutes.
    /// Which will be recieved from standard output.
    @Option(name: .short, help: "Duration of the resting timer, in minutes.")
    var restDuration: TimeInterval = 5.0
    
    /// Elapsed time which will be check against durations.
    private var elapsedTime: TimeInterval = 0.0

    private var state: State = .notStarted {
        didSet {
            #if DEBUG
                print(state)
            #endif
        }
    }

    /// Application state machine.
    private enum State: Codable, Comparable {
        /// Application has been fired but argument parser didnot hand it over.
        case notStarted

        /// Application is ready to start with given durations.
        case readyToStart(focusDuration: TimeInterval, restDuration: TimeInterval)

        /// Application is under `focus` state.
        case focus(TimeInterval)

        /// Application is under `rest` state.
        case rest(TimeInterval)

        /// Application is waiting for user's input.
        case waitingForConfirmation

        private var index: UInt8 {
            switch self {
                case .notStarted:
                    return 0

                case .readyToStart:
                    return 1

                case .focus:
                    return 2

                case .rest:
                    return 3

                case .waitingForConfirmation:
                    return UInt8.max
            }
        }

        static func < (lhs: State, rhs: State) -> Bool {
            return lhs.index < rhs.index
        }

        fileprivate mutating func startFocus(with duration: TimeInterval) {
            self = .focus(duration)
        }

        fileprivate mutating func startRest(with duration: TimeInterval) {
            self = .rest(duration)
        }
    }

    mutating func run() async throws {
        // initial state
        state = .readyToStart(
            focusDuration: focusDuration,
            restDuration: restDuration
        )

        // run loop
        while true {
            if !foo() {
                break
            }

            try await Task.sleep(for: .seconds(interval))
        }
    }

    private mutating func foo() -> Bool {
        // check for state change
        let finalDuration: TimeInterval = {
            switch state {
                case .focus:
                    return focusDuration

                case .rest:
                    return restDuration

                case .notStarted, .readyToStart, .waitingForConfirmation:
                    fatalError()
            }
        }()

        if elapsedTime >= finalDuration {
            let previousState = state

            state = .waitingForConfirmation

            let confirmationMessage: String

            switch previousState {
                case .focus:
                    confirmationMessage = "Lets take a break!\nPress 'Y' to continue."

                case .rest:
                    confirmationMessage = "Back to work!\nPress 'Y' to continue."

                default:
                    fatalError()
            }

            print(confirmationMessage)

            // ask for continuation
            let character = readLine()

            let canContinue = {
                guard let character else {
                    return false
                }

                return continuationCharacters.contains(character) ||
                continuationCharacters.contains(character.lowercased())
            }()

            guard canContinue else {
                return false
            }

            switch previousState {
                case .focus:
                    state = .rest(restDuration)
                    elapsedTime = 0

                case .rest:
                    state = .focus(focusDuration)
                    elapsedTime = 0

                case .notStarted, .readyToStart, .waitingForConfirmation:
                    fatalError()
            }
        }

        elapsedTime += 1

        printLoading(for: elapsedTime)

        return true
    }

    private func printLoading(for elapsedTime: TimeInterval) {
        var loadingBars = ""

        for _ in 0..<Int(elapsedTime) {
            loadingBars.append("|")
        }

        let loadingPercentage = Int(elapsedTime / focusDuration * 100)

        print("\(loadingBars) %\(loadingPercentage)", terminator: "\r")
        fflush(stdout)
    }
}
