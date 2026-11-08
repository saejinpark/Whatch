//
//  BatteryReading.swift
//  Whatch
//

import Foundation

/// A device's battery at one moment.
struct BatteryReading: Equatable, Sendable {
    enum Band: Equatable, Sendable {
        case unknown
        case low
        case medium
        case high
    }

    /// Level in `0...1`, or `nil` when unknown.
    var level: Double?
    var isCharging = false
    /// When the reading was taken, if it came from the other device.
    var updatedAt: Date?

    var band: Band {
        guard let level else { return .unknown }
        switch level {
        case ..<0.2: return .low
        case ..<0.5: return .medium
        default: return .high
        }
    }

    var percentText: String {
        guard let level else { return "--%" }
        return "\(Int((level * 100).rounded()))%"
    }

    /// "3분 전" style age, or `nil` when the reading is fresh or has no timestamp.
    func ageText(now: Date = Date()) -> String? {
        guard let updatedAt else { return nil }
        let seconds = now.timeIntervalSince(updatedAt)
        switch seconds {
        case ..<90: return nil
        case ..<3600: return "\(Int(seconds / 60))분 전"
        case ..<86_400: return "\(Int(seconds / 3600))시간 전"
        default: return "\(Int(seconds / 86_400))일 전"
        }
    }
}
