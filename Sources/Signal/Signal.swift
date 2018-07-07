public final class Signal<Value> {
    private var callbacks: Atomic<[Token: (Value) -> Void]>
    private let context: ExecutionContext?
    var disposeBag: DisposeBag
    
    private init(context: ExecutionContext?) {
        callbacks = Atomic([:])
        self.context = context
        disposeBag = DisposeBag()
    }
}

private extension Signal {
    final class Token {
        init() {}
    }
    
    convenience init(context: ExecutionContext?, _ process: (Sink<Value>) -> Void) {
        self.init(context: context)
        process(Sink(signal: self))
    }
    
    func perform(_ block: @escaping () -> Void) {
        if let context = context {
            context { block() }
        } else {
            block()
        }
    }
}

internal extension Signal {
    func send(_ value: Value) {
        callbacks.value.values.forEach { callback in
            perform { callback(value) }
        }
    }
}

public extension Signal {
    static var pending: Signal {
        return Signal(context: nil)
    }
    
    static func make() -> (signal: Signal, sink: Sink<Value>) {
        let signal = Signal.pending
        let sink = Sink(signal: signal)
        
        return (signal, sink)
    }
    
    convenience init(_ process: (Sink<Value>) -> Void) {
        self.init(context: nil, process)
    }
    
    func changeContext(_ context: @escaping ExecutionContext) -> Signal {
        return Signal(context: context) { sink in
            sink.subscribe(to: self)
        }
    }
}

extension Signal: Observable {
    public func subscribe(in disposeBag: DisposeBag, _ handler: @escaping (Value) -> Void) {
        let token = Token()
        callbacks.access { $0[token] = handler }
        
        disposeBag.add {
            self.callbacks.access { $0[token] = nil }
        }
    }
}

extension Signal.Token: Hashable {
    static func == (left: Signal.Token, right: Signal.Token) -> Bool {
        return left === right
    }
    
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}
