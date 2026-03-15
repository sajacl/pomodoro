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
}
