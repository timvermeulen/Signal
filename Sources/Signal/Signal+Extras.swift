public extension Signal {
    convenience init(
        asyncOn context: ExecutionContext,
        _ process: @escaping (Sink<Value>) -> Void
        ) {
        self.init { sink in
            context { process(sink) }
        }
    }
}
