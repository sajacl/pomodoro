import Testing
@testable import pomodoro

struct RoundTests {
    @Test
    func creation_nil() {
        let emptyCycles = Queue()
        let round = Round(cycles: emptyCycles)

        #expect(round == nil)
    }
}
