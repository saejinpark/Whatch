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
            .subscribe(.board, isOn: true),
            .subscribe(.motion, isOn: false),
            .subscribe(.pressure, isOn: true),
            .open(.controller),
            .setFlashlightBrightness(0.35),
            .board(Board().data),
            .buzz("... --- .../.-"),
            .controller(ControllerSample(tiltX: 0.25, tiltY: -0.5, yaw: 170.5, roll: -12, isPressed: true)),
            .controller(ControllerSample()),
            .duelStart(round: 421_337, delay: 3.25),
            .duelResult(round: 421_337, milliseconds: 287),
            .duelResult(round: 421_337, milliseconds: ReactionDuel.falseStart),
            .rangingOffer(Data([1, 2, 3, 250])),
            .rangingAnswer(Data([9, 8])),
            .rangingDistance(1.4375),
            .measureStart(.length, id: 1_794_000_000_123),
            .measureStart(.height, id: 7),
            .measureResult(id: 1_794_000_000_123, meters: 1.5625, isSteady: true),
            .measureResult(id: 7, meters: 0.25, isSteady: false),
            .measureStop(id: 1_794_000_000_123),
            .heartRate(72.5),
            .heartRate(0),
            .pressure(101.287),
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

    func testBrightnessTravelsWithTheState() throws {
        let decoded = try roundTrip(.state(DeviceState(flashlightBrightness: 0.4, timestamp: 9)))
        guard case .state(let state) = decoded else { return XCTFail("expected state") }
        XCTAssertEqual(state.flashlightBrightness, 0.4, accuracy: 1e-9)
        // A state from the previous app version has no brightness; assume full.
        let old = DeviceState(payload: ["timestamp": 1.0])
        XCTAssertEqual(old?.flashlightBrightness, 1)
    }

    func testMalformedNewMessagesAreRejected() {
        XCTAssertNil(WatchMessage(payload: ["kind": "subscribe", "value": ["stream": "gossip", "on": true]]))
        XCTAssertNil(WatchMessage(payload: ["kind": "open", "value": "teleporter"]))
        XCTAssertNil(WatchMessage(payload: ["kind": "controller", "value": [1.0, 2.0]]))
        XCTAssertNil(WatchMessage(payload: ["kind": "board", "value": "not data"]))
        XCTAssertNil(WatchMessage(payload: ["kind": "duelResult", "value": ["round": 1]]))
        XCTAssertNil(WatchMessage(payload: ["kind": "measureStart", "value": ["what": "weight", "id": 1]]))
        XCTAssertNil(WatchMessage(payload: ["kind": "measureResult", "value": ["id": 1, "m": 1.5]]))
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
