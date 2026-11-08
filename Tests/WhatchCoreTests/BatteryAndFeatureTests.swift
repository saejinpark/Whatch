import XCTest
@testable import WhatchCore

final class BatteryReadingTests: XCTestCase {
    func testBands() {
        XCTAssertEqual(BatteryReading(level: nil).band, .unknown)
        XCTAssertEqual(BatteryReading(level: 0.05).band, .low)
        XCTAssertEqual(BatteryReading(level: 0.2).band, .medium)
        XCTAssertEqual(BatteryReading(level: 0.5).band, .high)
        XCTAssertEqual(BatteryReading(level: 1).band, .high)
    }

    func testPercentText() {
        XCTAssertEqual(BatteryReading(level: nil).percentText, "--%")
        XCTAssertEqual(BatteryReading(level: 0.876).percentText, "88%")
        XCTAssertEqual(BatteryReading(level: 1).percentText, "100%")
    }

    func testAgeText() {
        let now = Date(timeIntervalSince1970: 100_000)
        func age(_ seconds: TimeInterval) -> String? {
            BatteryReading(level: 0.5, updatedAt: now.addingTimeInterval(-seconds)).ageText(now: now)
        }
        XCTAssertNil(BatteryReading(level: 0.5).ageText(now: now))
        XCTAssertNil(age(30))
        XCTAssertEqual(age(180), "3분 전")
        XCTAssertEqual(age(7_200), "2시간 전")
        XCTAssertEqual(age(172_800), "2일 전")
    }
}

final class FeatureTests: XCTestCase {
    func testEveryFeatureBelongsToExactlyOneGroup() {
        let grouped = Feature.Group.allCases.flatMap(\.features)
        XCTAssertEqual(grouped.count, Feature.allCases.count)
        XCTAssertEqual(Set(grouped), Set(Feature.allCases))
    }

    func testMetadataIsFilledIn() {
        for feature in Feature.allCases {
            XCTAssertFalse(feature.title.isEmpty)
            XCTAssertFalse(feature.detail.isEmpty)
            XCTAssertFalse(feature.systemImage.isEmpty)
            XCTAssertEqual(Feature(rawValue: feature.rawValue), feature)
        }
    }
}
