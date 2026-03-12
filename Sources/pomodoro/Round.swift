import Foundation

/// Object describing a round in pomodoro.
struct Round: Codable, Equatable {
    private var cycles: Queue

    var phase: Phase
//    var isFinished: Bool { cycles.count == 0 }

    init(cycleCount: UInt8, focusDuration: Duration, restDuration: Duration?) {
        cycles = Queue()

        for _ in 0..<(cycleCount - 1) {
            let cycle = Cycle(focus: focusDuration, rest: restDuration)

            cycles.enqueue(cycle)
        }

        // contains longer resting cycle
        cycles.enqueue(Cycle(focus: focusDuration, rest: 7.5 * Double(cycleCount)))

        phase = Phase(cycle: cycles.dequeue()!)
    }

    init(cycles: Queue) {
        self.cycles = cycles

        phase = Phase(cycle: self.cycles.dequeue()!)
    }

    mutating func next() -> Cycle? {
        cycles.dequeue()
    }

    mutating func moveForward() throws {
        if phase.state == .focusing, phase.cycle.rest != nil {
            phase.switchToRest()
        } else {
            try moveToNextCycle()
        }
    }

    private mutating func moveToNextCycle() throws {
        // replace phase with a new one
        // aka start fresh
        guard let newCycle = cycles.dequeue() else {
            throw ReachedEndOfCyclesFailure()
        }

        phase = Phase(cycle: newCycle)
    }
}

struct ReachedEndOfCyclesFailure: LocalizedError {
    var errorDescription: String? {
        "Reached the end of cycles."
    }
}
