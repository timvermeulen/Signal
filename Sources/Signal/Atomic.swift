import Foundation

final class Atomic<Value> {
    private var _value: Value
    private let queue: DispatchQueue
    
    init(_ value: Value, queue: DispatchQueue = DispatchQueue(label: "\(Atomic.self) queue")) {
        self._value = value
        self.queue = queue
    }
}

extension Atomic {
    func access<T>(_ block: (inout Value) -> T) -> T {
        return queue.sync { block(&_value) }
    }
    
    var value: Value {
        get { return access { $0 } }
        set { access { $0 = newValue } }
    }
}
