public struct BindingTarget<Value> {
    fileprivate let action: (Value) -> Void
    
    public init(_ action: @escaping (Value) -> Void) {
        self.action = action
    }
}

public extension Observable {
    func bind(to target: BindingTarget<Value>, in disposeBag: DisposeBag) {
        subscribe(in: disposeBag, target.action)
    }
}

public extension Observer {
    func bind<O: Observable>(_ observable: O, to target: BindingTarget<O.Value>) {
        observable.bind(to: target, in: disposeBag)
    }
}
