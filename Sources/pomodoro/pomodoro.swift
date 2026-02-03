import Foundation
import ArgumentParser

@main
@available(macOS 12, iOS 15, visionOS 1, tvOS 15, watchOS 8, *)
struct pomodoro: AsyncParsableCommand {
    @Argument(help: "Duration of the pomodoro timer, in minutes.")
    var focusDuration: TimeInterval = 25.0

    @Option(name: .short, help: "Duration of the resting timer, in minutes.")
    var restDuration: TimeInterval = 5.0

    mutating func run() async throws {
        print(focusDuration)
    }
}
