public struct Reactive<Base: AnyObject> {
    private let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

public extension Reactive {
    func bind<Value>(_ action: @escaping (Base, Value) -> Void) -> BindingTarget<Value> {
        return BindingTarget { [weak base] value in
            guard let base = base else { return }
            action(base, value)
        }
    }
}
