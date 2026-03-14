import Foundation

/// Allowed character that will move state forward.
private let continuationCharacters: Set<Character> = ["Y"]

extension Pomodoro {
    /// <#Description#>
    final class Iterator: Codable, Equatable {
        /// Boolean flag that indicates wheter the app should advance without asking.
        private let autoAdvance: Bool

        private let display: @MainActor (String) -> Void

        private let displayLoading: @MainActor (_ for: Duration, _ horizon: Duration) -> Void

        private let notify: @MainActor (String) -> Void

        /// List of cycles.
        private var round: Round!

        /// Elapsed time which will be check against durations.
        private var elapsedDuration: Duration = 0.0

        init(
            autoAdvance: Bool,
            display: @escaping @MainActor (String) -> Void = { ConsoleOutput.print($0) },
            displayLoading: @escaping @MainActor (Duration, Duration) -> Void = { ConsoleOutput.printLoading(for: $0, horizon: $1) },
            notify: @escaping @MainActor (String) -> Void = { NotificationProxy.notify(message: $0) }
        ) {
            self.autoAdvance = autoAdvance
            self.display = display
            self.displayLoading = displayLoading
            self.notify = notify
        }

        enum CodingKeys: String, CodingKey {
            case autoAdvance

            case round

            case elapsedDuration
        }

        // Decodable
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.autoAdvance = try container.decode(Bool.self, forKey: .autoAdvance)
            self.round = try container.decodeIfPresent(Round.self, forKey: .round)
            self.elapsedDuration = try container.decode(Duration.self, forKey: .elapsedDuration)

            // restore our default closures after decoding
            self.display = { ConsoleOutput.print($0) }
            self.displayLoading = { ConsoleOutput.printLoading(for: $0, horizon: $1) }
            self.notify = { NotificationProxy.notify(message: $0) }
        }

        static func == (lhs: Iterator, rhs: Iterator) -> Bool {
            lhs.autoAdvance == rhs.autoAdvance &&
            lhs.round == rhs.round &&
            lhs.elapsedDuration == rhs.elapsedDuration
        }

        func start(
            cycles: UInt8,
            with focusDuration: Duration,
            and restDuration: Duration?
        ) {
            round = Round(
                cycleCount: cycles,
                focusDuration: focusDuration,
                restDuration: focusDuration
            )
        }

        func start(with cycles: Queue) {
            round = Round(cycles: cycles)
        }

        func start(with cycles: [Cycle]) {
            round = Round(cycles: Queue(cycles))
        }

        @MainActor
        func advance() throws {
            // moving forward
            elapsedDuration += 1

            let horizon: Duration = round.cycle.phase.duration

            displayLoading(elapsedDuration, horizon)

            // counter book keeping

            let isCounterPassedHorizon: Bool = {
                let horizonDuration = horizon * 60

                return elapsedDuration >= horizonDuration
            }()

            if !isCounterPassedHorizon {
                // time has not passed yet
                return
            }

            // end of the current phase
            announceEndOfPhase()

            if autoAdvance || askUserForContinuation() {
                try moveForward()
            } else {
                throw CancellationError()
            }
        }

        @MainActor
        private func announceEndOfPhase() {
            let confirmationMessage: String

            switch round.cycle.phase {
                case .focused:
                    confirmationMessage = "Lets take a break! 🎉"

                case .resting:
                    confirmationMessage = "Work does not stop, grind does not stop! 💻"
            }

            notify(confirmationMessage)

            display("\n")
            display(confirmationMessage)
        }

        @MainActor
        private func askUserForContinuation() -> ShouldContinue {
            let continuationCharactersDescription = continuationCharacters
                .map { "'\($0)'" }
                .joined(separator: "|")

            display("Press \(continuationCharactersDescription) to continue.")

            // ask for continuation
            let character = readLine()?.first

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

        @MainActor
        private func moveForward() throws {
            let currentPhase = round.cycle.phase

            try round.moveForward()

            announceNewPhase(basedOn: currentPhase)

            elapsedDuration = 0.0
        }

        @MainActor
        private func announceNewPhase(basedOn oldPhase: Phase) {
            let message: String

            switch oldPhase {
                case let .focused(duration):
                    message = "[\(round.cycle.index)] Starting rest phase for '\(duration)' minutes."

                case let .resting(duration):
                    message = "[\(round.cycle.index)] Starting a new focus cycle for '\(duration)' minutes."
            }

            display(message)
        }

        // Encodable
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(autoAdvance, forKey: .autoAdvance)
            try container.encodeIfPresent(round, forKey: .round)
            try container.encode(elapsedDuration, forKey: .elapsedDuration)
        }
    }
}
