import Foundation

/// Object describing a round in pomodoro.
struct Round: Equatable, Codable {
    private var cycles: Queue

    private var currentCycle: Cycle

    private(set) var phase: Phase

    private(set) var index: UInt

    init(cycleCount: UInt8, focusDuration: Duration, restDuration: Duration?) {
        cycles = Queue()

        for _ in 0..<(cycleCount - 1) {
            let cycle = Cycle(focus: focusDuration, rest: restDuration)

            cycles.enqueue(cycle)
        }

        // contains longer resting cycle
        let lastRestCycle = {
            #if DEBUG
                return 0.1
            #else
                return 7.5 * Double(cycleCount)
            #endif
        }()

        cycles.enqueue(Cycle(focus: focusDuration, rest: lastRestCycle))

        currentCycle = cycles.dequeue()!

        phase = .focused(duration: currentCycle.focus)

        index = 1

        print("[\(index)] Starting a new focus cycle for '\(currentCycle.focus)' minutes.")
    }

    init?(cycles: Queue) {
        self.cycles = cycles

        guard let _cycle = self.cycles.dequeue() else {
            return nil
        }

        currentCycle = _cycle

        phase = .focused(duration: currentCycle.focus)

        index = 1

        print("[\(index)] Starting a new focus cycle for '\(currentCycle.focus)' minutes.")
    }

    mutating func moveForward() throws {
        switch phase {
            case .focused where currentCycle.rest != nil:
                phase = .resting(duration: currentCycle.rest!)

            default:
                try moveToNextCycle()
        }
    }

    private mutating func moveToNextCycle() throws {
        // replace phase with a new one
        // aka start fresh
        guard let newCycle = cycles.dequeue() else {
            throw ReachedEndOfCyclesFailure()
        }

        currentCycle = newCycle

        phase = .focused(duration: currentCycle.focus)

        let (_index, isOverflowed) = index.addingReportingOverflow(1)

        if isOverflowed {
            index = 1
        } else {
            index = _index
        }
    }
}

struct ReachedEndOfCyclesFailure: LocalizedError {
    var errorDescription: String? {
        "Reached the end of cycles."
    }
}
