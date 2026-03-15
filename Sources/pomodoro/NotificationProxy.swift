import Foundation

enum NotificationProxy {
    /// Sends a notification with given parameters.
    /// - Warning: Creates a sub-process.
    static func notify(title: String = "Pomodoro", message: String, subtitle: String? = nil) {
        var args = [
            "-e",
            "display notification \"\(esc(message))\" with title \"\(esc(title))\""
        ]

        if let subtitle {
            args[1] += " subtitle \"\(esc(subtitle))\""
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = args
        try? p.run()
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
