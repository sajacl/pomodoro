import Foundation
import Testing
@testable import pomodoro

@Suite("Pomodoro core journeys")
struct PomodoroTests {
    @Test("Initialization with autoAdvance sets flag and closures")
    func initialization() async throws {
        var displayedMessages: [String] = []
        var notifiedMessages: [String] = []
        var loadingCalls: [(Duration, Duration)] = []
        
        let pomodoro = Pomodoro(
            autoAdvance: true,
            display: { message in
                displayedMessages.append(message)
            },
            displayLoading: { duration, horizon in
                loadingCalls.append((duration, horizon))
            },
            notify: { message in
                notifiedMessages.append(message)
            }
        )
        
        // autoAdvance should be true
        #expect(Mirror(reflecting: pomodoro).descendant("autoAdvance") as? Bool == true)
    }
