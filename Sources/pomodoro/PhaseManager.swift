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
    private(set) var round: Round

    /// Elapsed time which will be check against durations.
    private(set) var elapsedTime: TimeInterval

    init(autoAdvance: Bool, cycles c: [Cycle]) {
        self.autoAdvance = autoAdvance
        cycles = Queue(cycles: c)

        elapsedTime = 0.0

        let cycle = cycles.dequeue()!

        round = Round(cycle: cycle)
    }

    mutating func start() {
        round.start()
    }

    @MainActor
    mutating func advance() -> ShouldContinue {
        guard let duration else {
            return false
        }

        // moving forward
        elapsedTime += 1

        ConsoleOutput.printLoading(for: elapsedTime, horizon: duration)

        // book keeping
        let isCounterPassedHorizon: Bool = {
            let horizonDuration = duration * 60

            return elapsedTime >= horizonDuration
        }()

        guard isCounterPassedHorizon else {
            // time has not passed yet
            return true
        }

        let currentRound = round
        announceEndOfThePhase(for: currentRound)

        if autoAdvance {
            return moveForward()
        }

        guard askUserForContinuation() else {
            return false
        }

        return moveForward()
    }

    private var duration: Duration? {
        guard let phase = round.phase else {
            return nil
        }

        switch phase {
            case .focusing:
                return round.cycle.focus

            case .resting:
                return round.cycle.rest
        }
    }

    private func announceEndOfThePhase(for round: Round) {
        let confirmationMessage: String

        switch round.phase {
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
    private func askUserForContinuation() -> ShouldContinue {
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

    private mutating func moveForward() -> ShouldContinue {
        let message: String

        switch round.phase {
            case .focusing:
                if let restDuration = round.cycle.rest {
                    message = "Starting rest phase for '\(restDuration)' minutes."

                    // advance phase
                    round.switchToRest()
                } else {
                    let cycle = startNewRound()

                    message = "Starting a new focus cycle for '\(cycle.focus)' minutes"
                }

            case .resting:
                let cycle = startNewRound()

                message = "Starting a new focus cycle for '\(cycle.focus)' minutes"

            default:
                return false
        }

        elapsedTime = 0

        print(message)

        return true
    }

    private mutating func startNewRound() -> Cycle {
        // replace phase with a new one
        // aka start fresh
        let cycle = cycles.dequeue()!
        let newPhase = Round(cycle: cycle)

        round = newPhase

        round.start()

        return cycle
    }
}
