import Testing
@testable import pomodoro

struct Test {
    @Test
    func creation() async throws {
        var queue = Queue()

        #expect(queue.isEmpty)

        let mockQueue = Cycle.mock

        queue.enqueue(mockQueue)

        #expect(queue.dequeue() == mockQueue)
    }

    @Test
    func enqueue() async throws {
        var queue = Queue()

        #expect(queue.isEmpty)

        let mockQueue = Cycle.mock

        queue.enqueue(mockQueue)

        #expect(queue.isEmpty == false)
    }

    @Test
    func dequeue() async throws {
        var queue = Queue()

        #expect(queue.isEmpty)

        let mockQueue = Cycle.mock

        queue.enqueue(mockQueue)

        #expect(queue.dequeue() == mockQueue)
    }
}

private extension Cycle {
    static let mock = Cycle(focus: 1.0, rest: 1.0)
}
