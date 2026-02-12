import Foundation

/// Visual progress bar length.
private let loadingBarWidth: Int = 30

@MainActor
enum ConsoleOutput {
    /// Tracks previous loading output's length for clean overwriting.
    private static var lastLoadingOutputLength: Int = 0

    /// Method responsible for printing out the loading bar based on `elapsedTime` and `horizon` duration.
    static func printLoading(for elapsedTime: TimeInterval, horizon: Duration) {
        // Spinner animation frames
        let spinnerFrames = ["|", "/", "-", "\\"]
        let spinner = spinnerFrames[Int(elapsedTime) % spinnerFrames.count]

        let barWidth = loadingBarWidth

        let progress = min(elapsedTime / (horizon * 60), 1.0)

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
