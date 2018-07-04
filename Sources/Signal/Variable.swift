public final class Variable<Value> {
    private var atomicValue: Atomic<Value>
    private let signal: Signal<Value>
    private let sink: Sink<Value>
    
    public init(value: Value) {
        atomicValue = Atomic(value)
        (signal, sink) = Signal.make()
    }
}

extension Variable: Observer {
    public var disposeBag: DisposeBag {
        return signal.disposeBag
    }
}

extension Variable: Observable {
    public func subscribe(in disposeBag: DisposeBag, _ handler: @escaping (Value) -> Void) {
        handler(value)
        return signal.subscribe(in: disposeBag, handler)
    }
}

public extension Variable {
    convenience init(_ signal: Signal<Value>, initial: Value) {
        self.init(value: initial)
        
        subscribe(to: signal) { [weak self] value in
            self?.value = value
        }
    }
    
    var value: Value {
        get {
            return atomicValue.value
        }
        set {
            atomicValue.value = newValue
            sink.send(newValue)
        }
    }
    
    func map<T>(_ transform: @escaping (Value) -> T) -> Variable<T> {
        return .init(signal.map(transform), initial: transform(value))
    }
}
