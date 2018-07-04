import XCTest
import Signal

extension Observable where Value: Equatable {
    func assertWillProduce(
        _ expectedValues: [Value],
        file: StaticString = #file,
        line: UInt = #line,
        _ block: () -> Void
    ) {
        var values: [Value] = []
        let disposeBag = DisposeBag()
        
        subscribe(in: disposeBag) { values.append($0) }
        withExtendedLifetime(disposeBag, block)
        
        XCTAssertEqual(values, expectedValues, file: file, line: line)
    }
}
