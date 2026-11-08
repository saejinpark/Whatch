import XCTest
@testable import WhatchCore

final class WatchMessageTests: XCTestCase {
    /// Simulates the trip through WatchConnectivity, which bridges values to NSNumber/NSDictionary.
    private func roundTrip(_ message: WatchMessage) throws -> WatchMessage? {
        let data = try PropertyListSerialization.data(fromPropertyList: message.payload, format: .binary, options: 0)
        let decoded = try PropertyListSerialization.propertyList(from: data, format: nil)
        return WatchMessage(payload: try XCTUnwrap(decoded as? [String: Any]))
    }

    func testEveryCaseSurvivesARoundTrip() throws {
        let state = DeviceState(batteryLevel: 0.87, isCharging: true, isFlashlightOn: true,
                                isHapticOn: false, isForeground: true, timestamp: 1_700_000_000.5)
        let messages: [WatchMessage] = [
            .ping(sentAt: 1_700_000_000.123456),
            .pong(sentAt: 1_700_000_000.123456),
            .setFlashlight(isOn: true),
            .setFlashlight(isOn: false),
            .setHaptic(isOn: true),
            .headingSubscription(isOn: true),
            .headingSubscription(isOn: false),
            .heading(359.5),
            .state(state),
            .state(DeviceState(timestamp: 1)),
            .stateRequest,
        ]
        for message in messages {
            XCTAssertEqual(try roundTrip(message), message)
        }
    }

    func testUnknownBatteryStaysUnknown() throws {
        let decoded = try roundTrip(.state(DeviceState(batteryLevel: nil, timestamp: 5)))
        guard case .state(let state) = decoded else { return XCTFail("expected state") }
        XCTAssertNil(state.batteryLevel)
    }

    func testPayloadIsAPropertyList() {
        let payload = WatchMessage.state(DeviceState(batteryLevel: 0.5, timestamp: 1)).payload
        XCTAssertTrue(PropertyListSerialization.propertyList(payload, isValidFor: .binary))
    }

    func testGarbageIsRejected() {
        XCTAssertNil(WatchMessage(payload: [:]))
        XCTAssertNil(WatchMessage(payload: ["kind": "nope"]))
        XCTAssertNil(WatchMessage(payload: ["kind": "ping"]))
        XCTAssertNil(WatchMessage(payload: ["kind": "ping", "value": "soon"]))
        XCTAssertNil(WatchMessage(payload: ["kind": "state", "value": ["battery": 0.5]]))
        // Messages from the previous app version must not be misread.
        XCTAssertNil(WatchMessage(payload: ["request": "FlashLightToggle:ON"]))
    }
}
