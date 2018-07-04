public final class Signal<Value> {
    private var callbacks: Atomic<[Token: (Value) -> Void]>
    let disposeBag: DisposeBag
    
    private init() {
        callbacks = Atomic([:])
        disposeBag = DisposeBag()
    }
}

private extension Signal {
    final class Token {
        init() {}
    }
}

internal extension Signal {
    func send(_ value: Value) {
        callbacks.value.values.forEach { $0(value) }
    }
}

public extension Signal {
    static var pending: Signal {
        return Signal()
    }
    
    static func make() -> (signal: Signal, sink: Sink<Value>) {
        let signal = Signal.pending
        let sink = Sink(signal: signal)
        
        return (signal, sink)
    }
    
    convenience init(_ work: (Sink<Value>) -> Void) {
        self.init()
        work(Sink(signal: self))
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
