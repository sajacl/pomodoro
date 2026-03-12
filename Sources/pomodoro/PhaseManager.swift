import Foundation

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

/// Object that manages
struct PhaseManager: Codable, Equatable {
    /// Boolean flag that indicates wheter the app should advance without asking.
    private let autoAdvance: Bool

    /// List of cycles.
    private var cycles: Queue

    /// <#Description#>
    private(set) var phase: Phase?

    /// Elapsed time which will be check against durations.
    private(set) var elapsedTime: TimeInterval

    init(autoAdvance: Bool, cycles: [Cycle]) {
        self.autoAdvance = autoAdvance
        self.cycles = Queue(cycles: cycles)

        elapsedTime = 0.0
    }

    mutating func start() {
        guard let cycle = cycles.dequeue() else {
            fatalError()
        }

        print("Starting a new cycle for \(cycle.focus + (cycle.rest ?? 0)) minutes")

        phase = Phase(cycle: cycle)
    }

    @MainActor
    mutating func advance() -> CanContinue {
        guard let duration else {
            return false
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
        let previousPhase = phase

        announceEndOfTheCycle(previousPhase: previousPhase)

        if autoAdvance {
            moveForward(from: previousPhase)
            return true
        }

        guard askUserForContinuation() else {
            return false
        }

        moveForward(from: previousPhase)

        return true
    }

    private mutating func moveForward(from previousPhase: Phase?) {
        let message: String

        switch previousPhase?.state {
            case .focusing:
                let restDuration = previousPhase?.cycle.rest ?? 0
                message = "Starting a rest phase for \(restDuration) minutes."

                // advance phase
                phase?.startResting()

            case .resting:
                phase = nil

                // replace phase with a new one
                // aka start fresh
                let cycle = cycles.dequeue()!
                let newPhase = Phase(cycle: cycle)

                message = "Starting a new cycle for \(cycle.focus) minutes"

                phase = newPhase

            default:
                fatalError("Checking state change needs in an invalid state.")
        }

        elapsedTime = 0

        print(message)
    }

    // MARK: Counter management

    private var duration: Duration? {
        guard let phase = phase else {
            return nil
        }

        switch phase.state {
            case .focusing:
                return phase.cycle.focus

            case .resting:
                return phase.cycle.rest
        }
    }

    private func announceEndOfTheCycle(previousPhase: Phase?) {
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
    }

    // MARK: Continuation check
    private func askUserForContinuation() -> Bool {
        let continuationCharactersDescription = continuationCharacters
            .map { "'\($0)'" }
            .joined(separator: "|")

        print("Press \(continuationCharactersDescription) to continue.")

        // ask for continuation
        let character = readLine()

        let shouldContinue = {
            guard let character else {
                return false
            }

            return continuationCharacters
                .contains(where: { continuationCharacter in
                    continuationCharacter.lowercased() == character.lowercased()
                })
        }()

        return shouldContinue
    }
}
