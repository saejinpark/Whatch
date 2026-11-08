import XCTest
@testable import WhatchCore

final class HeadingMathTests: XCTestCase {
    func testNormalized() {
        XCTAssertEqual(HeadingMath.normalized(0), 0)
        XCTAssertEqual(HeadingMath.normalized(360), 0)
        XCTAssertEqual(HeadingMath.normalized(-90), 270)
        XCTAssertEqual(HeadingMath.normalized(725), 5)
    }

    func testDifferenceTakesTheShortWay() {
        XCTAssertEqual(HeadingMath.difference(from: 350, to: 10), 20)
        XCTAssertEqual(HeadingMath.difference(from: 10, to: 350), -20)
        XCTAssertEqual(HeadingMath.difference(from: 0, to: 180), 180)
        XCTAssertEqual(HeadingMath.difference(from: 90, to: 90), 0)
        XCTAssertEqual(HeadingMath.difference(from: 0, to: 181), -179)
    }

    func testCardinal() {
        XCTAssertEqual(HeadingMath.cardinal(for: 0), "북")
        XCTAssertEqual(HeadingMath.cardinal(for: 359), "북")
        XCTAssertEqual(HeadingMath.cardinal(for: 44), "북동")
        XCTAssertEqual(HeadingMath.cardinal(for: 90), "동")
        XCTAssertEqual(HeadingMath.cardinal(for: 180), "남")
        XCTAssertEqual(HeadingMath.cardinal(for: 270), "서")
        XCTAssertEqual(HeadingMath.cardinal(for: -45), "북서")
    }
}
