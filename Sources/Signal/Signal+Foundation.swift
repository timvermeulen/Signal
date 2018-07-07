import Foundation

public extension Signal {
    convenience init(asyncOn queue: DispatchQueue, _ process: @escaping (Sink<Value>) -> Void) {
        self.init(asyncOn: queue.asyncContext, process)
    }
    
    func on(_ queue: DispatchQueue) -> Signal {
        return changeContext(queue.asyncContext)
    }
    
//    func debounce() -> Signal {
//        return compactMap(state: <#T##State#>, <#T##transform: (inout State, Value) -> T?##(inout State, Value) -> T?#>)
//    }
}
