public protocol Observable {
    associatedtype Value
    func subscribe(in disposeBag: DisposeBag, _ handler: @escaping (Value) -> Void)
}
