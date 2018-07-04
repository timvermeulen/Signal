import XCTest

import SignalTests

var tests = [XCTestCaseEntry]()
tests += SignalTests.allTests()
XCTMain(tests)