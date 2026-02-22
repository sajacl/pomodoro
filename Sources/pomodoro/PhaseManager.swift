import Foundation

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

/// Object that manages
@MainActor
struct PhaseManager: Codable, Equatable {
    /// Boolean flag that indicates wheter the app should advance without asking.
    private let autoAdvance: Bool

    /// List of cycles.
    private var cycles: [Cycle]

    /// <#Description#>
    private(set) var currentPhase: Phase?

    /// Elapsed time which will be check against durations.
    private(set) var elapsedTime: TimeInterval

    init(autoAdvance: Bool, cycles: [Cycle]) {
        self.autoAdvance = autoAdvance
        self.cycles = cycles

        elapsedTime = 0.0
    }

    mutating func start() {
        let cycle = cycles.removeFirst()

        print("Starting a new cycle for \(cycle.focus) minutes")

        currentPhase = Phase(cycle: cycle)
    }

    mutating func advance() -> CanContinue {
        guard let duration else {
            return true
        }

        elapsedTime += 1

        ConsoleOutput.printLoading(for: elapsedTime, horizon: duration)

        let isCounterPassedHorizon: Bool = {
            let horizonDuration = duration * 60

            return elapsedTime >= horizonDuration
        }()

        guard isCounterPassedHorizon else {
            // time has not passed yet
            return true
        }

        // check for state change needs
        let previousPhase = currentPhase

        if !autoAdvance,
           !askUserIfWantsToContinue(previousPhase: previousPhase) {
            return false
        }

        let message: String

        switch previousPhase?.state {
            case .focusing:
                let restDuration = previousPhase?.cycle.rest ?? 0
                message = "Starting a rest phase for \(restDuration) minutes."

                // advance phase
                currentPhase?.startResting()

            case .resting:
                currentPhase = nil

                // replace phase with a new one
                // aka start fresh
                let cycle = cycles.removeFirst()
                let newPhase = Phase(cycle: cycle)

                message = "Starting a new cycle for \(cycle.focus) minutes"

                currentPhase = newPhase

            default:
                fatalError("Checking state change needs in an invalid state.")
        }

        elapsedTime = 0

        print(message)

        return true
    }

    // MARK: Counter management

    private var duration: Duration? {
        guard let phase = currentPhase else {
            return nil
        }

        switch phase.state {
            case .focusing:
                return phase.cycle.focus

            case .resting:
                return phase.cycle.rest
        }
    }

    // MARK: Continuation check
    private mutating func askUserIfWantsToContinue(previousPhase: Phase?) -> Bool {
        let confirmationMessage: String

        switch previousPhase?.state {
            case .focusing:
                confirmationMessage = "Lets take a break! 🎉"

            case .resting:
                confirmationMessage = "Back to work!"

            default:
                fatalError("Asking user to continue in an invalid state.")
        }

        NotificationProxy.notify(title: "Pomodoro", message: confirmationMessage)

        print("\n")
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
}
