public final class Sink<Value> {
    private weak var signal: Signal<Value>?
    
    init(signal: Signal<Value>) {
        self.signal = signal
    }
}

extension Sink: Observer {
    public var disposeBag: DisposeBag {
        // return an empty dispose bag if `signal` is deallocated
        return signal?.disposeBag ?? DisposeBag()
    }
}

public extension Sink {
    convenience init() {
        self.init(signal: .pending)
    }
    
    func send(_ value: Value) {
        signal?.send(value)
    }
    
    func subscribe<O: Observable>(to observable: O) where O.Value == Value {
        subscribe(to: observable, send)
    }
}

public extension Sink where Value == Void {
    func send() {
        send(())
    }
}
