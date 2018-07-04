final class Disposable {
    private let dispose: () -> Void
    
    init(_ block: @escaping () -> Void) {
        self.dispose = block
    }
    
    deinit {
        dispose()
    }
}

public final class DisposeBag {
    private var disposables: [Disposable]
    
    public init() {
        disposables = []
    }
    
    func add(block: @escaping () -> Void) {
        disposables.append(Disposable(block))
    }
}
