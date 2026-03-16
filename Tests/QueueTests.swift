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

    @Test
    func copy_assignment() async throws {
        var queue1 = Queue()

        #expect(queue1.isEmpty)

        let mockQueue = Cycle.mock

        queue1.enqueue(mockQueue)

        let queue2 = queue1

        #expect(queue1.dequeue() == mockQueue)
        #expect(queue1.isEmpty)

        #expect(!queue2.isEmpty)
    }
}

private extension Cycle {
    static let mock = Cycle(focus: 1.0, rest: 1.0)
}
