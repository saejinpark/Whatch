import XCTest
@testable import WhatchCore

final class RotationAccumulatorTests: XCTestCase {
    func testAccumulatesAcrossTheWrapAround() {
        var rotation = RotationAccumulator()
        // Two full clockwise turns in 30° steps, with angles reported in -180...180.
        for step in 0...24 {
            var angle = Double(step * 30).truncatingRemainder(dividingBy: 360)
            if angle > 180 { angle -= 360 }
            rotation.add(angle: angle)
        }
        XCTAssertEqual(rotation.totalDegrees, 720, accuracy: 1e-9)
        XCTAssertEqual(rotation.turns, 2, accuracy: 1e-9)
    }

    func testCounterClockwiseIsNegative() {
        var rotation = RotationAccumulator()
        for angle in [0.0, -90, -179, 179, 90] {
            rotation.add(angle: angle)
        }
        XCTAssertEqual(rotation.totalDegrees, -270, accuracy: 1e-9)
    }

    func testMovementWhilePausedIsIgnored() {
        var rotation = RotationAccumulator()
        rotation.add(angle: 0)
        rotation.add(angle: 10)
        rotation.isPaused = true
        rotation.add(angle: 100)
        rotation.isPaused = false
        rotation.add(angle: 110)
        XCTAssertEqual(rotation.totalDegrees, 20, accuracy: 1e-9)
    }

    func testResetStartsFromTheNextSample() {
        var rotation = RotationAccumulator()
        rotation.add(angle: 0)
        rotation.add(angle: 50)
        rotation.reset()
        rotation.add(angle: 120)
        XCTAssertEqual(rotation.totalDegrees, 0)
    }
}

final class ImpactMeterTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 0)

    func testRestingWristReadsOneG() {
        var meter = ImpactMeter()
        meter.add(x: 0, y: 0, z: -1, at: start)
        XCTAssertEqual(meter.current, 1, accuracy: 1e-9)
        XCTAssertEqual(meter.equivalentMass, ImpactMeter.armMass, accuracy: 1e-9)
        XCTAssertEqual(meter.count, 0)
    }

    func testOneSwingIsCountedOnce() {
        var meter = ImpactMeter(threshold: 1.5, debounce: 0.5)
        // A swing stays above the threshold for several 50 Hz samples.
        for index in 0..<10 {
            meter.add(x: 3, y: 0, z: 0, at: start.addingTimeInterval(Double(index) * 0.02))
        }
        XCTAssertEqual(meter.count, 1)
        meter.add(x: 4, y: 0, z: 0, at: start.addingTimeInterval(1))
        XCTAssertEqual(meter.count, 2)
        XCTAssertEqual(meter.peak, 4, accuracy: 1e-9)
    }

    func testPeakSurvivesInitAndResetClearsIt() {
        var meter = ImpactMeter(peak: 5)
        meter.add(x: 1, y: 0, z: 0, at: start)
        XCTAssertEqual(meter.peak, 5)
        meter.reset()
        XCTAssertEqual(meter.peak, 0)
        XCTAssertEqual(meter.count, 0)
    }
}

final class VibrationAnalyzerTests: XCTestCase {
    func testStillWristIsCalm() {
        var analyzer = VibrationAnalyzer()
        for _ in 0..<20 {
            analyzer.add(x: 0, y: 0, z: -1)
        }
        XCTAssertEqual(analyzer.level, .calm)
        XCTAssertEqual(analyzer.peak, 0)
        XCTAssertEqual(analyzer.samples.count, 19) // The first reading has nothing to compare with.
    }

    func testShakingIsIntenseAndBufferIsCapped() {
        var analyzer = VibrationAnalyzer(sampleLimit: 30)
        for index in 0..<100 {
            analyzer.add(x: index.isMultiple(of: 2) ? 1 : -1, y: 0, z: 0)
        }
        XCTAssertEqual(analyzer.level, .intense)
        XCTAssertEqual(analyzer.samples.count, 30)
        XCTAssertEqual(analyzer.peak, 2, accuracy: 1e-9)
    }

    func testGentleMovementIsInBetween() {
        var analyzer = VibrationAnalyzer()
        for index in 0..<20 {
            analyzer.add(x: index.isMultiple(of: 2) ? 0.05 : -0.05, y: 0, z: 0)
        }
        XCTAssertEqual(analyzer.level, .moving)
    }
}
