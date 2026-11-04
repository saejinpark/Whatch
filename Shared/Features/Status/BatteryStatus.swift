//
//  BatteryStatus.swift
//  Whatch
//

import SwiftUI

/// Battery level of one of the two devices. `nil` means the level is not known yet.
enum BatteryStatus: LockUpItem {
    case watch(level: Float?)
    case phone(level: Float?)

    private var level: Float? {
        switch self {
        case .watch(let level), .phone(let level): level
        }
    }

    private var deviceName: String {
        switch self {
        case .watch: "Apple Watch"
        case .phone: "iPhone"
        }
    }

    var title: String {
        let percent = level.map { "\(Int($0 * 100))%" } ?? "--%"
        return "\(deviceName)\n\(percent)"
    }

    var systemImage: String {
        switch self {
        case .watch: "applewatch"
        case .phone: "iphone"
        }
    }

    var tint: Color {
        guard let level else { return .secondary }
        switch level {
        case ..<0.2: return .red
        case ..<0.5: return .yellow
        default: return .green
        }
    }
}
