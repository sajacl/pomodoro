import Foundation
import ArgumentParser

@main
@available(macOS 12, iOS 15, visionOS 1, tvOS 15, watchOS 8, *)
struct pomodoro: AsyncParsableCommand {
    @Argument(help: "Duration of the pomodoro timer, in minutes.")
    var focusDuration: TimeInterval = 25.0

    @Option(name: .short, help: "Duration of the resting timer, in minutes.")
    var restDuration: TimeInterval = 5.0

    private enum State: Codable, Comparable {
        case notStarted

        case focus(TimeInterval)

        case rest(TimeInterval)

        case askingForConfirmation

        private var index: UInt8 {
            switch self {
                case .notStarted:
                    return 0

                case .focus:
                    return 1

                case .rest:
                    return 2

                case .askingForConfirmation:
                    return 3
            }
        }

        static func < (lhs: State, rhs: State) -> Bool {
            return lhs.index < rhs.index
        }
    }
    mutating func run() async throws {
        print(focusDuration)
    }
}
