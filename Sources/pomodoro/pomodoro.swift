import Foundation
import ArgumentParser

/// Gap interval in seconds.
private let interval: Duration = 1.0

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

/// Visual progress bar length.
private let loadingBarWidth: Int = 30

private typealias CanContinue = Bool

private typealias Duration = TimeInterval

@main
@available(macOS 12, iOS 15, visionOS 1, tvOS 15, watchOS 8, *)
struct pomodoro: AsyncParsableCommand {
    /// Duration of the pomodoro timer, in minutes.
    /// Which will be recieved from standard output.
    @Argument(help: "Duration of the pomodoro timer, in minutes.")
    var focusDuration: TimeInterval = {
        #if DEBUG
            return 5.0
        #else
            return 25.0
        #endif
    }()

    /// Duration of the rest timer, in minutes.
    /// Which will be recieved from standard output.
    @Option(
        name: [.customLong("rest"), .customShort("r")],
        help: "Duration of the resting timer, in minutes."
    )
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
    
    /// Tracks previous loading output's length for clean overwriting.
    private var lastLoadingOutputLength: Int = 0

    /// Application state machine.
    private enum State: Codable, Comparable {
        /// Application has been fired but argument parser didnot hand it over.
        case notStarted

        /// Application is ready to start with given durations.
        case readyToStart(focusDuration: Duration, restDuration: Duration)

        /// Application is under `focus` state.
        case focus(Duration)

        /// Application is under `rest` state.
        case rest(Duration)

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

        fileprivate mutating func startFocus(with duration: Duration) {
            self = .focus(duration)
        }

        fileprivate mutating func startRest(with duration: Duration) {
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

    private mutating func foo() -> CanContinue {
        // first start point
        if case let .readyToStart(focusDuration, _) = state {
            state = .focus(focusDuration)
        }

        elapsedTime += 1

        printLoading(for: elapsedTime)

        guard isCounterPassedHorizon else {
            // time has not passed yet
            return true
        }

        // check for state change needs
        let previousState = state

        guard askUserIfWantsToContinue() else {
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
                fatalError("Checking state change needs in an invalid state.")
        }

        return true
    }

    // MARK: Counter management

    private var duration: Duration {
        switch state {
            case .focus:
                return focusDuration
                
            case .rest:
                return restDuration
                
            case .notStarted, .readyToStart, .waitingForConfirmation:
                fatalError("Getting duration in an invalid state.")
        }
    }

    private var isCounterPassedHorizon: Bool {
        let horizonDuration = duration * 60

        return elapsedTime >= horizonDuration
    }

    // MARK: Continuation check
    private mutating func askUserIfWantsToContinue() -> Bool {
        let previousState = state

        state = .waitingForConfirmation

        let confirmationMessage: String

        switch previousState {
            case .focus:
                confirmationMessage = "Lets take a break! 🎉"

            case .rest:
                confirmationMessage = "Back to work!"

            default:
                fatalError("Asking user to continue in an invalid state.")
        }

        notify(title: "Pomodoro", message: confirmationMessage)

        print(confirmationMessage)
        print("Press 'Y' to continue.")

        // ask for continuation
        let character = readLine()

        let shouldContinue = {
            guard let character else {
                return false
            }

            return continuationCharacters.contains(character) ||
            continuationCharacters.contains(character.uppercased())
        }()

        return shouldContinue
    }

    // MARK: Loading bar
    private mutating func printLoading(for elapsedTime: TimeInterval) {
        // Spinner animation frames
        let spinnerFrames = ["|", "/", "-", "\\"]
        let spinner = spinnerFrames[Int(elapsedTime) % spinnerFrames.count]

        let barWidth = loadingBarWidth

        let progress = min(elapsedTime / (duration * 60), 1.0)

        let filledBars = Int(progress * Double(barWidth))

        let emptyBars = barWidth - filledBars

        let filledBarsStr = String(repeating: "█", count: filledBars)
        let emptyBards = String(repeating: "░", count: emptyBars)
        let bar = filledBarsStr + emptyBards

        let loadingPercentage = Int(progress * 100)
        var output = "\(spinner) [\(bar)] \(loadingPercentage)%"

        // Pad with spaces if output is shorter than last one
        let paddingLength = lastLoadingOutputLength - output.count

        if paddingLength > 0 {
            output += String(repeating: " ", count: paddingLength)
        }

        print("\r\(output)", terminator: "")
        fflush(stdout)

        lastLoadingOutputLength = output.count
    }
}

private func notify(title: String, message: String, subtitle: String? = nil) {
    func esc(_ s: String) -> String { s.replacingOccurrences(of: "\"", with: "\\\"") }

    var args = ["-e", "display notification \"\(esc(message))\" with title \"\(esc(title))\""]

    if let s = subtitle { args[1] += " subtitle \"\(esc(s))\"" }

    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    p.arguments = args
    try? p.run()
}
