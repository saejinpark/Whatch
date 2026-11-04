//
//  PingStatus.swift
//  Whatch
//

import SwiftUI

enum PingStatus: LockUpItem {
    case good
    case bad
    case pending

    var title: String {
        switch self {
        case .good: "연결 양호"
        case .bad: "연결 불량"
        case .pending: "대기 중"
        }
    }

    var systemImage: String {
        switch self {
        case .good: "checkmark.circle"
        case .bad: "xmark.octagon"
        case .pending: "hourglass"
        }
    }

    var tint: Color {
        switch self {
        case .good: .green
        case .bad: .red
        case .pending: .gray
        }
    }
}
