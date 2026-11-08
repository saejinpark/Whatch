import XCTest
@testable import WhatchCore

final class TorchLevelTests: XCTestCase {
    func testFullBrightnessAsksForTheMaximum() {
        XCTAssertEqual(TorchLevel(brightness: 1), .maximum)
        XCTAssertEqual(TorchLevel(brightness: 0.999), .maximum)
        XCTAssertEqual(TorchLevel(brightness: 7), .maximum)
    }

    /// The slider's whole range must map to a level AVFoundation accepts. Scaling the
    /// "maximum" sentinel by the brightness once crashed the app at every setting below 100%.
    func testEveryDimmerSettingIsAValidFraction() {
        for step in 0...89 {
            let brightness = 0.1 + Double(step) * 0.01
            guard case .fraction(let level) = TorchLevel(brightness: brightness) else {
                return XCTFail("\(brightness) should be a fraction")
            }
            XCTAssertGreaterThan(level, 0)
            XCTAssertLessThanOrEqual(level, 1)
            XCTAssertEqual(Double(level), brightness, accuracy: 1e-6)
        }
    }

    func testOutOfRangeValuesAreClamped() {
        XCTAssertEqual(TorchLevel(brightness: 0), .fraction(0.1))
        XCTAssertEqual(TorchLevel(brightness: -3), .fraction(0.1))
        XCTAssertEqual(TorchLevel(brightness: .nan), .maximum)
        XCTAssertEqual(TorchLevel(brightness: .infinity), .maximum)
    }
}
