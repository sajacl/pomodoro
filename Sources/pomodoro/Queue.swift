import Foundation

/// A simple FIFO queue implemented as a singly linked list for storing `Cycle` values.
struct Queue: Equatable, Codable, Sequence, CustomDebugStringConvertible {
    /// The first node in the queue.
    private var head: Node?

    /// Initializes a queue with a list of cycles.
    init(cycles: [Cycle]) {
        for cycle in cycles {
            enqueue(cycle)
        }
    }

    /// The last node in the queue.
    private var tail: Node? {
        var node: Node? = head

        while let currentNode = node, let next = currentNode.next {
            node = next
        }

        return node
    }

    /// Ensures this queue has unique ownership of its nodes before mutating.
    private mutating func ensureUnique() {
        guard let head, !isKnownUniquelyReferenced(&self.head) else {
            return
        }

        // Make a deep copy of all nodes
        var oldNode = head
        let newHead = Node(value: oldNode.value)
        var newNode = newHead

        while let nextOld = oldNode.next {
            let copied = Node(value: nextOld.value)
            newNode.next = copied
            newNode = copied
            oldNode = nextOld
        }

        self.head = newHead
    }

    /// Adds a `Cycle` to the end of the queue.
    mutating func enqueue(_ cycle: Cycle) {
        ensureUnique()

        if head == nil {
            head = Node(value: cycle)
        } else {
            tail?.next = Node(value: cycle)
        }
    }

    /// Removes and returns the `Cycle` at the front of the queue.
    mutating func dequeue() -> Cycle? {
        ensureUnique()

        guard let _head = head else {
            return nil
        }

        head = _head.next

        return _head.value
    }

    /// Returns an iterator over the queue's cycles.
    func makeIterator() -> Iterator {
        Iterator(self)
    }

    /// A string describing the queue's contents, useful for debugging.
    var debugDescription: String {
        var str = ""

        for cycle in self {
            str += "\(cycle)->"
        }

        if head != nil {
            str.removeLast(2)
        }

        return str
    }

    /// A node in the linked list.
    private final class Node: Equatable, Codable {
        /// The value stored in the node.
        let value: Cycle

        /// The next node in the list.
        var next: Node?

        /// Initializes a node with a value and optional next node.
        init(value: Cycle, next: Node? = nil) {
            self.value = value
            self.next = next
        }

        static func == (lhs: Node, rhs: Node) -> Bool {
            return lhs.value == rhs.value && lhs.next == rhs.next
        }
    }

    /// Iterator for traversing the queue.
    struct Iterator: IteratorProtocol {
        private var current: Node?
        
        /// Creates an iterator for the given queue.
        init(_ queue: Queue) {
            current = queue.head
        }
        
        /// Advances to the next cycle in the queue.
        mutating func next() -> Cycle? {
            defer { current = current?.next }
            return current?.value
        }
    }
}
