public protocol Observable {
    associatedtype Value
    func subscribe(in disposeBag: DisposeBag, _ process: @escaping (Value) -> Void)
}
