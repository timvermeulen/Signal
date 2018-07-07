import XCTest
import Signal

final class SignalTests: XCTestCase {
    func testDistinctUntilChanged() {
        let (signal, sink) = Signal<Int>.make()
        
        signal.distinctUntilChanged().assertWillProduce([3, 8, 11]) {
            sink.send(3)
            sink.send(8)
            sink.send(8)
            sink.send(11)
        }
    }
    
    func testScan() {
        let (signal, sink) = Signal<Int>.make()
        
        signal.scan(0, +).assertWillProduce([0, 3, 8, 10, 18]) {
            sink.send(3)
            sink.send(5)
            sink.send(2)
            sink.send(8)
        }
    }
    
    func testWithLatest() {
        let (signal1, sink1) = Signal<Int>.make()
        let (signal2, sink2) = Signal<String>.make()
        let combined = signal1.withLatest(from: signal2).map { "\($0)\($1)" }
        
        combined.assertWillProduce(["2A", "3D", "4D", "5D"]) {
            sink1.send(1)
            sink2.send("A")
            sink1.send(2)
            sink2.send("B")
            sink2.send("C")
            sink2.send("D")
            sink1.send(3)
            sink1.send(4)
            sink1.send(5)
        }
    }
    
    func testBuffer() {
        let (signal1, sink1) = Signal<Int>.make()
        let (signal2, sink2) = Signal<Void>.make()
        
        signal1.buffered(with: signal2).assertWillProduce([[1, 2, 3], [4, 5], [], [6]]) {
            sink1.send(1)
            sink1.send(2)
            sink1.send(3)
            sink2.send()
            sink1.send(4)
            sink1.send(5)
            sink2.send()
            sink2.send()
            sink1.send(6)
            sink2.send()
            sink1.send(7)
        }
    }
    
    func testBufferCount() {
        let (signal, sink) = Signal<Int>.make()
        
        signal.buffered(count: 3).assertWillProduce([[1, 2, 3], [4, 5, 6], [7, 8, 9]]) {
            (1...10).forEach(sink.send)
        }
    }
    
    func testVariable() {
        let variable = Variable(123)
        
        variable.assertWillProduce([123, 100, 200]) {
            variable.value = 100
            variable.value = 200
        }
    }
    
    func testVariableMap() {
        let variable1 = Variable(123)
        let variable2 = variable1.map { $0 * 2 }
        
        variable2.assertWillProduce([246, 20, 200]) {
            variable1.value = 10
            variable1.value = 100
        }
    }
    
    func testBinding() {
        let object = Object()
        
        let (signal, sink) = Signal<String>.make()
        let disposeBag = DisposeBag()
        signal.bind(to: Reactive(object).value, in: disposeBag)
        
        withExtendedLifetime(disposeBag) {
            for string in ["abc", "def", "ghi"] {
                sink.send(string)
                XCTAssertEqual(object.value, string)
            }
        }
    }
}

final class Object {
    var value: String?
}

extension Reactive where Base == Object {
    var value: BindingTarget<String> {
        return bind { $0.value = $1 }
    }
}
