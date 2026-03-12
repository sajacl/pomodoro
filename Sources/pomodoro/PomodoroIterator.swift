import Foundation

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

extension pomodoro {
    /// <#Description#>
    struct Iterator: Codable, Equatable {
        /// Boolean flag that indicates wheter the app should advance without asking.
        private let autoAdvance: Bool

        /// List of cycles.
        private var round: Round!

        enum State: Codable, Equatable {
            case notStarted

            case advancing

            case finished
        }

        /// <#Description#>
        private var state: State = .notStarted

        /// Elapsed time which will be check against durations.
        private var elapsedDuration: Duration = 0.0

        init(autoAdvance: Bool) {
            self.autoAdvance = autoAdvance
        }

        mutating func start(
            cycles: UInt8,
            with focusDuration: Duration,
            and restDuration: Duration?
        ) {
            round = Round(
                cycleCount: cycles,
                focusDuration: focusDuration,
                restDuration: focusDuration
            )

            state = .advancing
        }

        mutating func start(with cycles: Queue) {
            round = Round(cycles: cycles)

            state = .advancing
        }

        mutating func start(with cycles: [Cycle]) {
            round = Round(cycles: Queue(cycles))

            state = .advancing
        }

        @MainActor
        mutating func advance() -> ShouldContinue {
            switch state {
                case .notStarted:
                    fatalError("Use start first!")

                case .advancing:
                    return advance(round: round)

                case .finished:
                    startNewRoundIfPossible()

                    return false
            }
        }

        @MainActor
        private mutating func advance(round: Round) -> ShouldContinue {
            // moving forward
            elapsedDuration += 1

            let horizon: Duration

            switch round.phase.state {
                case .focusing:
                    horizon = round.phase.cycle.focus

                case .resting:
                    if let restingDuration = round.phase.cycle.rest {
                        horizon = restingDuration
                    } else {
                        // start new cycle
                        // goto new focusing if possible

                        return false
                    }
            }

            ConsoleOutput.printLoading(for: elapsedDuration, horizon: horizon)

            // book keeping
            let isCounterPassedHorizon: Bool = {
                let horizonDuration = horizon * 60

                return elapsedDuration >= horizonDuration
            }()

            guard isCounterPassedHorizon else {
                // time has not passed yet
                return true
            }

            let currentPhase = round.phase.state
            announceEndOfThePhase(currentPhase)

            if autoAdvance {
                return moveForward()
            }

            guard askUserForContinuation() else {
                return false
            }

            return moveForward()
        }

        private func announceEndOfThePhase(_ state: Phase.State) {
            let confirmationMessage: String

            switch state {
                case .focusing:
                    confirmationMessage = "Lets take a break! 🎉"

                case .resting:
                    confirmationMessage = "Back to work!"
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
            let currentPhase = round.phase

            let couldAdvanceCurrentPhase: Bool

            switch state {
                case .notStarted:
                    fatalError()

                case .advancing:
                    do {
                        try round.moveForward()

                        couldAdvanceCurrentPhase = true
                    } catch {
                        startNewRoundIfPossible()

                        couldAdvanceCurrentPhase = false
                    }

                case .finished:
                    startNewRoundIfPossible()

                    couldAdvanceCurrentPhase = false
            }

            announceCompletion(
                previousState: state,
                currentPhase: currentPhase.state,
                couldAdvanceCurrentPhase: couldAdvanceCurrentPhase
            )

            elapsedDuration = 0

            return true
        }

        private func announceCompletion(
            previousState: State,
            currentPhase: Phase.State,
            couldAdvanceCurrentPhase: Bool
        ) {
            let message: String

            switch state {
                case .notStarted:
                    fatalError()

                case .advancing:
                    if couldAdvanceCurrentPhase {
                        switch currentPhase {
                            case .focusing:
                                if let restDuration = round.phase.cycle.rest {
                                    message = "Starting rest phase for '\(restDuration)' minutes."
                                } else {
                                    message = "Starting a new focus cycle without resting for '\(round.phase.cycle.focus)' minutes"
                                }

                            case .resting:
                                message = "Starting a new focus cycle for '\(round.phase.cycle.focus)' minutes"
                        }
                    } else {
                        message = "Starting a new round!"
                    }

                case .finished:
                    message = "Starting a new round!"
            }

            print(message)
        }

        private mutating func startNewRoundIfPossible() {
//            let newRound = Round(cycles: 4)
//
//            return newRound
//            return nil
        }
    }
}
