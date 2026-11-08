//
//  WatchMessage.swift
//  Whatch
//

import Foundation

/// A snapshot of one device, sent to the other so both screens agree.
struct DeviceState: Equatable, Sendable {
    /// Battery level in `0...1`, or `nil` when unknown.
    var batteryLevel: Double?
    var isCharging = false
    var isFlashlightOn = false
    var isHapticOn = false
    /// Whether the app is on screen. The iPhone torch and haptics need this.
    var isForeground = false
    /// When the snapshot was taken, in seconds since 1970.
    var timestamp: TimeInterval = 0

    private enum Key {
        static let battery = "battery"
        static let charging = "charging"
        static let flashlight = "flashlight"
        static let haptic = "haptic"
        static let foreground = "foreground"
        static let timestamp = "timestamp"
    }

    init(
        batteryLevel: Double? = nil,
        isCharging: Bool = false,
        isFlashlightOn: Bool = false,
        isHapticOn: Bool = false,
        isForeground: Bool = false,
        timestamp: TimeInterval = 0
    ) {
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.isFlashlightOn = isFlashlightOn
        self.isHapticOn = isHapticOn
        self.isForeground = isForeground
        self.timestamp = timestamp
    }

    var payload: [String: Any] {
        var payload: [String: Any] = [
            Key.charging: isCharging,
            Key.flashlight: isFlashlightOn,
            Key.haptic: isHapticOn,
            Key.foreground: isForeground,
            Key.timestamp: timestamp,
        ]
        if let batteryLevel {
            payload[Key.battery] = batteryLevel
        }
        return payload
    }

    init?(payload: [String: Any]) {
        guard let timestamp = payload[Key.timestamp] as? NSNumber else { return nil }
        self.timestamp = timestamp.doubleValue
        batteryLevel = (payload[Key.battery] as? NSNumber)?.doubleValue
        isCharging = (payload[Key.charging] as? NSNumber)?.boolValue ?? false
        isFlashlightOn = (payload[Key.flashlight] as? NSNumber)?.boolValue ?? false
        isHapticOn = (payload[Key.haptic] as? NSNumber)?.boolValue ?? false
        isForeground = (payload[Key.foreground] as? NSNumber)?.boolValue ?? false
    }
}

/// Every message exchanged between the iPhone and Watch apps.
///
/// WatchConnectivity only carries property-list values, so each case is encoded as a
/// small dictionary (`kind` + optional `value`) and decoded back on the other side.
enum WatchMessage: Equatable, Sendable {
    /// Round-trip probe. The receiver answers with `.pong` carrying the same timestamp.
    case ping(sentAt: TimeInterval)
    case pong(sentAt: TimeInterval)
    /// Watch → iPhone: turn the torch on or off. Answered with `.state`.
    case setFlashlight(isOn: Bool)
    /// Watch → iPhone: start or stop the vibration. Answered with `.state`.
    case setHaptic(isOn: Bool)
    /// Asks the receiver to start or stop streaming `.heading`. Sent when the heading
    /// screen opens and closes, so the link is not flooded when nobody is looking.
    case headingSubscription(isOn: Bool)
    /// Sender's compass heading in degrees, streamed while the receiver is subscribed.
    case heading(Double)
    /// Sender's current state.
    case state(DeviceState)
    /// Asks the receiver to answer with `.state`.
    case stateRequest

    private enum Kind: String {
        case ping, pong, setFlashlight, setHaptic, headingSubscription, heading, state, stateRequest
    }

    private enum Key {
        static let kind = "kind"
        static let value = "value"
    }

    var payload: [String: Any] {
        switch self {
        case .ping(let sentAt): encode(.ping, sentAt)
        case .pong(let sentAt): encode(.pong, sentAt)
        case .setFlashlight(let isOn): encode(.setFlashlight, isOn)
        case .setHaptic(let isOn): encode(.setHaptic, isOn)
        case .headingSubscription(let isOn): encode(.headingSubscription, isOn)
        case .heading(let degrees): encode(.heading, degrees)
        case .state(let state): encode(.state, state.payload)
        case .stateRequest: encode(.stateRequest, nil)
        }
    }

    init?(payload: [String: Any]) {
        guard let rawKind = payload[Key.kind] as? String,
              let kind = Kind(rawValue: rawKind) else { return nil }
        let value = payload[Key.value]
        let number = value as? NSNumber

        switch kind {
        case .ping:
            guard let number else { return nil }
            self = .ping(sentAt: number.doubleValue)
        case .pong:
            guard let number else { return nil }
            self = .pong(sentAt: number.doubleValue)
        case .setFlashlight:
            guard let number else { return nil }
            self = .setFlashlight(isOn: number.boolValue)
        case .setHaptic:
            guard let number else { return nil }
            self = .setHaptic(isOn: number.boolValue)
        case .headingSubscription:
            guard let number else { return nil }
            self = .headingSubscription(isOn: number.boolValue)
        case .heading:
            guard let number else { return nil }
            self = .heading(number.doubleValue)
        case .state:
            guard let dictionary = value as? [String: Any],
                  let state = DeviceState(payload: dictionary) else { return nil }
            self = .state(state)
        case .stateRequest:
            self = .stateRequest
        }
    }

    private func encode(_ kind: Kind, _ value: Any?) -> [String: Any] {
        var payload: [String: Any] = [Key.kind: kind.rawValue]
        if let value {
            payload[Key.value] = value
        }
        return payload
    }
}
