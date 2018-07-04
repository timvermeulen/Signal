public protocol Observer {
    var disposeBag: DisposeBag { get }
}

public extension Observer {
    func subscribe<O: Observable>(to observable: O, _ handler: @escaping (O.Value) -> Void) {
        observable.subscribe(in: disposeBag, handler)
    }
}
