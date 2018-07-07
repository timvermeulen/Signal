import XCTest
import Signal

extension Observable where Value: Equatable {
    func assertWillProduce(
        _ expectedValues: [Value],
        file: StaticString = #file,
        line: UInt = #line,
        _ block: () -> Void
    ) {
        let values = scan(into: []) { $0.append($1) }
        block()
        XCTAssertEqual(values.value, expectedValues, file: file, line: line)
    }
}
