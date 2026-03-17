import Testing
@testable import pomodoro

struct RoundTests {
    @Test
    func creation_nil() {
        let emptyCycles = Queue()
        let round = Round(cycles: emptyCycles)

        #expect(round == nil)
    }

    @Test
    func creation_not_nil() {
        let cyclesCount = 1

        let focus: Duration = 1.0
        let rest: Duration = 1.0

        var cycles = Queue()

        for _ in 0..<(cyclesCount) {
            let cycle = Cycle(focus: focus, rest: rest)

            cycles.enqueue(cycle)
        }

        let round = Round(cycles: cycles)

        #expect(round != nil)
    }

    @Test
    func creation_firstCycle_equals() throws {
        let cyclesCount = 1

        let focus: Duration = 1.0
        let rest: Duration = 1.0

        var cycles = Queue()

        for _ in 0..<(cyclesCount) {
            let cycle = Cycle(focus: focus, rest: rest)

            cycles.enqueue(cycle)
        }

        let round = try #require(Round(cycles: cycles))

        let _firstCycle = cycles.dequeue()
        let firstCycle = try #require(_firstCycle)

        let mockActiveCycle = Round.ActiveCycle(
            index: 1,
            cycle: firstCycle,
            phase: .focused
        )

        #expect(round.cycle == mockActiveCycle)
    }

    @Test
    @MainActor
    func moveForward_focusToRest_transition() throws {
        let cycle = Cycle(focus: 1.0, rest: 2.0)
        var queue = Queue()
        queue.enqueue(cycle)

        var round = try #require(Round(cycles: queue))
        #expect(round.cycle.phase == .focused)

        try round.moveForward()

        #expect(round.cycle.phase == .resting)
        #expect(round.cycle.duration == 2.0)
    }

    @Test
    @MainActor
    func moveForward_restToNextCycle_transition() throws {
        // Two cycles
        let first = Cycle(focus: 1.0, rest: 2.0)
        let second = Cycle(focus: 3.0, rest: 4.0)

        var queue = Queue()
        queue.enqueue(first)
        queue.enqueue(second)

        var round = try #require(Round(cycles: queue))
        // Move to rest of first cycle
        try round.moveForward()

        #expect(round.cycle.phase == .resting)

        // Move to next cycle
        try round.moveForward()

        #expect(round.cycle.index == 2)
        #expect(round.cycle.phase == .focused)
        #expect(round.cycle.duration == 3.0)
    }
}
