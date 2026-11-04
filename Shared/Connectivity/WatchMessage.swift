//
//  WatchMessage.swift
//  Whatch
//

import Foundation

/// Every message exchanged between the iPhone and Watch apps.
///
/// `WCSession.sendMessage` only carries property-list values, so each case is
/// encoded as a two-key dictionary (`kind` + `value`) and decoded back on the other side.
enum WatchMessage: Equatable, Sendable {
    /// Round-trip probe. The receiver answers with `.pong` carrying the same timestamp.
    case ping(sentAt: TimeInterval)
    case pong(sentAt: TimeInterval)
    /// Watch → iPhone: requested flashlight state. iPhone → Watch: actual flashlight state.
    case flashlight(isOn: Bool)
    /// Watch → iPhone: requested haptic state. iPhone → Watch: actual haptic state.
    case haptic(isOn: Bool)
    /// Sender's true heading in degrees.
    case heading(Double)
    /// Sender's battery level in `0...1`.
    case batteryLevel(Float)

    private enum Kind: String {
        case ping, pong, flashlight, haptic, heading, batteryLevel
    }

    private enum Key {
        static let kind = "kind"
        static let value = "value"
    }

    var payload: [String: Any] {
        switch self {
        case .ping(let sentAt): return encode(.ping, sentAt)
        case .pong(let sentAt): return encode(.pong, sentAt)
        case .flashlight(let isOn): return encode(.flashlight, isOn)
        case .haptic(let isOn): return encode(.haptic, isOn)
        case .heading(let degrees): return encode(.heading, degrees)
        case .batteryLevel(let level): return encode(.batteryLevel, level)
        }
    }

    init?(payload: [String: Any]) {
        guard let rawKind = payload[Key.kind] as? String,
              let kind = Kind(rawValue: rawKind) else { return nil }
        let number = payload[Key.value] as? NSNumber

        switch kind {
        case .ping:
            guard let number else { return nil }
            self = .ping(sentAt: number.doubleValue)
        case .pong:
            guard let number else { return nil }
            self = .pong(sentAt: number.doubleValue)
        case .flashlight:
            guard let number else { return nil }
            self = .flashlight(isOn: number.boolValue)
        case .haptic:
            guard let number else { return nil }
            self = .haptic(isOn: number.boolValue)
        case .heading:
            guard let number else { return nil }
            self = .heading(number.doubleValue)
        case .batteryLevel:
            guard let number else { return nil }
            self = .batteryLevel(number.floatValue)
        }
    }

    private func encode(_ kind: Kind, _ value: Any) -> [String: Any] {
        [Key.kind: kind.rawValue, Key.value: value]
    }
}
