public extension Observable {
    func async(_ context: @escaping ExecutionContext) -> Signal<Value> {
        return transform { sink, value in
            context { sink.send(value) }
        }
    }
    
    func transform<State, T>(
        state: State, _ process: @escaping (inout State, Sink<T>, Value) -> Void
    ) -> Signal<T> {
        var state = state
        
        return .init { sink in
            sink.subscribe(to: self) { value in
                process(&state, sink, value)
            }
        }
    }
    
    func transform<T>(_ process: @escaping (Sink<T>, Value) -> Void) -> Signal<T> {
        return .init { sink in
            sink.subscribe(to: self) { value in
                process(sink, value)
            }
        }
    }
    
    func map<State, T>(
        state: State,
        _ transform: @escaping (inout State, Value) -> T
    ) -> Signal<T> {
        return self.transform(state: state) { state, sink, value in
            sink.send(transform(&state, value))
        }
    }
    
    func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return self.transform { sink, value in sink.send(transform(value)) }
    }
    
    func flatMap<State, T>(
        state: State,
        _ transform: @escaping (inout State, Value) -> Signal<T>
    ) -> Signal<T> {
        return self.transform(state: state) { state, sink, value in
            sink.subscribe(to: transform(&state, value))
        }
    }
    
    func flatMap<T>(_ transform: @escaping (Value) -> Signal<T>) -> Signal<T> {
        return self.transform { sink, value in
            sink.subscribe(to: transform(value))
        }
    }
    
    func filter(_ isIncluded: @escaping (Value) -> Bool) -> Signal<Value> {
        return transform { sink, value in
            if isIncluded(value) {
                sink.send(value)
            }
        }
    }
    
    func compactMap<T, State>(
        state: State,
        _ transform: @escaping (inout State, Value) -> T?
    ) -> Signal<T> {
        return self.transform(state: state) { state, sink, value in
            if let transformed = transform(&state, value) {
                sink.send(transformed)
            }
        }
    }
    
    func compactMap<T>(_ transform: @escaping (Value) -> T?) -> Signal<T> {
        return self.transform { sink, value in
            guard let transformed = transform(value) else { return }
            sink.send(transformed)
        }
    }
    
    func compact<T>() -> Signal<T> where Value == T? {
        return compactMap { $0 }
    }
    
    func drop(while predicate: @escaping (Value) -> Bool) -> Signal<Value> {
        return transform(state: true) { isIdle, sink, value in
            if isIdle {
                if predicate(value) {
                    return
                } else {
                    isIdle = false
                }
            }
            
            sink.send(value)
        }
    }
    
    func prefix(while predicate: @escaping (Value) -> Bool) -> Signal<Value> {
        return transform(state: true) { isActive, sink, value in
            guard isActive else { return }
            
            if predicate(value) {
                sink.send(value)
            } else {
                isActive = false
            }
        }
    }
    
    func withPrevious() -> Signal<(previous: Value?, value: Value)> {
        return map(state: nil as Value?) { previous, value in
            defer { previous = value }
            return (previous, value)
        }
    }
    
    func distinctUntilChanged(by areEqual: @escaping (Value, Value) -> Bool) -> Signal<Value> {
        return withPrevious().compactMap { previous, value in
            guard let previous = previous else { return value }
            return areEqual(value, previous) ? nil : value
        }
    }
    
    func scan<State>(
        into state: State,
        _ process: @escaping (inout State, Value) -> Void
    ) -> Variable<State> {
        let signal: Signal<State> = transform(state: state) { state, sink, value in
            process(&state, value)
            sink.send(state)
        }
        
        return Variable(signal, initial: state)
    }
    
    func scan<State>(
        _ state: State,
        _ transform: @escaping (State, Value) -> State
    ) -> Variable<State> {
        return scan(into: state) { state, value in
            state = transform(state, value)
        }
    }
    
    func withLatest<T>(from signal: Signal<T>) -> Signal<(Value, T)> {
        return combine(self, signal).compactMap(state: nil as T?) { latest, either in
            switch either {
            case .left(let value):
                return latest.map { (value, $0) }
            case .right(let value):
                latest = value
                return nil
            }
        }
    }
    
    func buffered(with signal: Signal<Void>) -> Signal<[Value]> {
        return combine(self, signal).compactMap(state: [] as [Value]) { buffer, either in
            switch either {
            case .left(let value):
                buffer.append(value)
                return nil
            case .right:
                defer { buffer.removeAll() }
                return buffer
            }
        }
    }
    
    func buffered(count: Int) -> Signal<[Value]> {
        precondition(count > 0)
        
        return compactMap(state: [] as [Value]) { buffer, value in
            buffer.append(value)
            
            if buffer.count == count {
                defer { buffer.removeAll(keepingCapacity: true) }
                return buffer
            } else {
                return nil
            }
        }
    }
}

public extension Observable where Value: Equatable {
    func distinctUntilChanged() -> Signal<Value> {
        return distinctUntilChanged(by: ==)
    }
}

func zip<T, U>(_ left: Signal<T>, _ right: Signal<U>) -> Signal<(T, U)> {
    var latest: (left: T?, right: U?)
    
    return .init { sink in
        sink.subscribe(to: left) { left in
            latest.left = left
            
            if let right = latest.right {
                sink.send((left, right))
            }
        }
        
        sink.subscribe(to: right) { right in
            latest.right = right
            
            if let left = latest.left {
                sink.send((left, right))
            }
        }
    }
}

func merge<T, O1: Observable, O2: Observable>(
    _ left: O1,
    _ right: O2
) -> Signal<T> where O1.Value == T, O2.Value == T {
    return Signal { sink in
        sink.subscribe(to: left)
        sink.subscribe(to: right)
    }
}

func combine<Left: Observable, Right: Observable>(
    _ left: Left,
    _ right: Right
) -> Signal<Either<Left.Value, Right.Value>> {
    return merge(left.map(Either.left), right.map(Either.right))
}
