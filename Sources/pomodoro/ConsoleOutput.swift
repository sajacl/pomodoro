import Foundation

/// Visual progress bar length.
private let loadingBarWidth: Int = 30

@MainActor
enum ConsoleOutput {
    /// Tracks the previous loading output length for proper console overwrite.
    private static var lastLoadingOutputLength: Int = 0

    /// Prints a progress/loading bar to the console, reflecting elapsed time versus a set duration.
    static func printLoading(for elapsedDuration: Duration, horizon: Duration) {
        // Spinner animation frames
        let spinnerFrames = ["|", "/", "-", "\\"]
        let spinner = spinnerFrames[Int(elapsedDuration) % spinnerFrames.count]

        let barWidth = loadingBarWidth

        let progress = min(elapsedDuration / (horizon * 60.0), 1.0)

        let filledBars = Int(progress * Duration(barWidth))

        let emptyBars = barWidth - filledBars

        let filledBarsStr = String(repeating: "█", count: filledBars)
        let emptyBards = String(repeating: "░", count: emptyBars)
        let bar = filledBarsStr + emptyBards

        let loadingPercentage = Int(progress * 100.0)
        var output = "\(spinner) [\(bar)] \(loadingPercentage)%"

        // Pad with spaces if output is shorter than last one
        let paddingLength = lastLoadingOutputLength - output.count

        if paddingLength > 0 {
            output += String(repeating: " ", count: paddingLength)
        }

        Swift.print("\r\(output)", terminator: "")
        fflush(stdout)

        lastLoadingOutputLength = output.count
    }

    static func print(_ str: String) {
        Swift.print(str)
    }
}
