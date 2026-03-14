import Foundation

/// Object describing a round in pomodoro.
struct Round: Equatable, Codable {
    private var cycles: Queue

    private(set) var cycle: ActiveCycle

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

        let _cycle = cycles.dequeue()!
        let index: UInt = 1

        cycle = ActiveCycle(index: index, cycle: _cycle)

        print("[\(index)] Starting a new focus cycle for '\(_cycle.focus)' minutes.")
    }

    init?(cycles: Queue) {
        self.cycles = cycles

        guard let _cycle = self.cycles.dequeue() else {
            return nil
        }

        let index: UInt = 1

        cycle = ActiveCycle(index: index, cycle: _cycle)

        print("[\(index)] Starting a new focus cycle for '\(_cycle.focus)' minutes.")
    }

    mutating func moveForward() throws {
        switch cycle.phase {
            case .focused where cycle.cycle.rest != nil:
                cycle.phase = .resting

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

        var index = cycle.index

        let (newIndex, overflow) = index.addingReportingOverflow(1)

        if overflow {
            // starting from the beginning
            index = 1
        } else {
            index = newIndex
        }

        cycle = ActiveCycle(index: index, cycle: newCycle, phase: .focused)
    }
}
