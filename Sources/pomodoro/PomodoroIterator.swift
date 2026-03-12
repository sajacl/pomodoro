import Foundation

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

extension pomodoro {
    /// <#Description#>
    struct Iterator: Codable, Equatable {
        /// Boolean flag that indicates wheter the app should advance without asking.
        private let autoAdvance: Bool

        /// List of cycles.
        private var cycles: Queue

        /// <#Description#>
        private var currentRound: Round

        /// Elapsed time which will be check against durations.
        private var elapsedTime: TimeInterval

        init(autoAdvance: Bool, cycles c: [Cycle]) {
            self.autoAdvance = autoAdvance
            cycles = Queue(cycles: c)

            elapsedTime = 0.0

            let cycle = cycles.dequeue()!

            currentRound = Round(cycle: cycle)
        }

        mutating func start() {
            currentRound.start()
        }

        @MainActor
        mutating func advance() -> ShouldContinue {
            let duration: Duration? = {
                guard let phase = currentRound.phase else {
                    return nil
                }

                switch phase {
                    case .focusing:
                        return currentRound.cycle.focus

                    case .resting:
                        return currentRound.cycle.rest
                }
            }()

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

            let _currentRound = currentRound
            announceEndOfThePhase(for: _currentRound)

            if autoAdvance {
                return moveForward()
            }

            guard askUserForContinuation() else {
                return false
            }

            return moveForward()
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

            switch currentRound.phase {
                case .focusing:
                    if let restDuration = currentRound.cycle.rest {
                        message = "Starting rest phase for '\(restDuration)' minutes."

                        // advance phase
                        currentRound.switchToRest()
                    } else {
                        // move immediatly to next cycle.
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
            guard let cycle = cycles.dequeue() else {
                fatalError()
            }

            let newPhase = Round(cycle: cycle)

            currentRound = newPhase

            currentRound.start()

            return cycle
        }
    }
}
