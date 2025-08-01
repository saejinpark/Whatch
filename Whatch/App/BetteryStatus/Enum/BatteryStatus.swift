//
//  BatteryStatus.swift
//  Whatch
//
//  Created by 박세진 on 7/13/25.
//

import SwiftUI

enum BatteryStatus: LockUpItem {
    case phone(level: Float)
    case watch(level: Float)

    var description: String {
        switch self {
        case .phone(let level):
            return "iPhone\n\(Int(level * 100))%"
        case .watch(let level):
            return "Apple Watch\n\(Int(level * 100))%"
        }
    }

    var systemImage: String {
        switch self {
        case .phone:
            return "iphone"
        case .watch:
            return "applewatch"
        }
    }

    var color: Color {
        switch self {
        case .phone(let level), .watch(let level):
            switch level {
            case ..<0.2: return .red
            case ..<0.5: return .yellow
            default: return .green
            }
        }
    }
}
