import Foundation

/// Object describing a round in pomodoro.
struct Round: Equatable, Codable {
    /// The queue of remaining cycles in this round.
    private var cycles: Queue

    /// The currently active cycle (focus or rest phase).
    private(set) var cycle: ActiveCycle

    init?(cycles: Queue) {
        self.cycles = cycles

        guard let _cycle = self.cycles.dequeue() else {
            return nil
        }

        let index: UInt = 1

        cycle = ActiveCycle(index: index, cycle: _cycle)

        print("[\(index)] Starting a new focus cycle for '\(_cycle.focus)'.")
    }

    private init(nonEmptyQueue queue: Queue) {
        cycles = queue

        let _cycle = cycles.dequeue()!
        let index: UInt = 1

        cycle = ActiveCycle(index: index, cycle: _cycle)

        print("[\(index)] Starting a new focus cycle for '\(_cycle.focus)'.")
    }

    /// Default means last cycle has more rest phase duration.
    static func makeDefault(fromCycles count: UInt8, focus: Duration, rest: Duration) -> Round {
        var cycles = Queue()

        for _ in 0..<(count - 1) {
            let cycle = Cycle(focus: focus, rest: rest)

            cycles.enqueue(cycle)
        }

        // contains longer resting cycle
        let lastRestCycle: Duration = {
            #if DEBUG
                return 0.1
            #else
                return 7.5 * Duration(count)
            #endif
        }()

        cycles.enqueue(Cycle(focus: focus, rest: lastRestCycle))

        return Round(nonEmptyQueue: cycles)
    }

    @MainActor
    mutating func advance() -> ActiveCycle.Iterator.Result {
        cycle.advance()
    }

    /// Advances the round to the next phase or cycle.
    ///
    /// - If the current phase is a focused phase and a rest phase exists, transitions to the rest phase of the current cycle.
    /// - Otherwise, moves to the next cycle and starts its focus phase.
    /// - Throws: `ReachedEndOfCyclesFailure` if all cycles in the round have been completed.
    @MainActor
    mutating func moveForward() throws {
        switch cycle.phase {
            case .focused where cycle.cycle.rest != 0.0:
                cycle.transitionToRestPhase()

            default:
                try moveToNextCycle()
        }
    }

    @MainActor
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

// MARK: ActiveCycle
extension Round {
    /// Object describing the current cycle (aka active cycle).
    struct ActiveCycle: Equatable, Codable {
        /// The index of this cycle in the round, starting from 1.
        let index: UInt

        /// The underlying cycle (focus/rest durations).
        fileprivate let cycle: Cycle

        /// The phase (focused or resting) currently active.
        fileprivate(set) var phase: Phase

        private var iterator: Iterator

        fileprivate init(index: UInt, cycle: Cycle, phase: Phase = .focused) {
            self.index = index
            self.cycle = cycle
            self.phase = phase

            iterator = Iterator(horizon: cycle.focus)
        }

        /// The duration (in minutes) of the current phase.
        var duration: Duration {
            switch phase {
                case .focused:
                    return cycle.focus

                case .resting:
                    return cycle.rest
            }
        }

        @MainActor
        fileprivate mutating func advance() -> Iterator.Result {
            iterator.next()
        }

        @MainActor
        fileprivate mutating func transitionToRestPhase() {
            phase = .resting

            iterator = Iterator(horizon: cycle.rest)
        }
    }
}
